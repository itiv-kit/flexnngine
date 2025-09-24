library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;
    use accel.sync.bit_sync;

entity acc_axi_top is
  generic (
    size_x : positive := 5;
    size_y : positive := 5;

    -- pe line buffer length per data type
    line_length_iact : positive := 64;
    line_length_wght : positive := 64;
    line_length_psum : positive := 128;

    -- internal data types
    data_width_input : positive := 8;  -- size of a iact/wght word
    data_width_psum  : positive := 16; -- size of a result word in the PE accumulator / line buffer

    -- address widths scratchpad <-> external, port_a is exposed as i/o on this module
    mem_addr_width_bytes : positive := 19; -- defines memory size in bytes, default to 512KiB
    mem_word_count       : positive := 8;
    mem_data_width       : positive := 64; -- vivado does not like expressions here: mem_word_count * data_width_input

    fifo_size_iact : positive := 16;
    fifo_size_wght : positive := 16;
    fifo_size_psum : positive := 32;

    dataflow         : integer := 0;
    postproc_enabled : boolean := true;
    use_float_ip     : boolean := true;

    -- enable cdc between AXI and accelerator clock domains if clocks differ
    axi_acc_cdc : boolean := false;

    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 9
  );
  port (
    clk    : in std_logic;
    clk_sp : in std_logic;

    o_irq : out std_logic;

    -- unused rst port to make up a valid Vivado interface spec (VLNV)
    i_dummy_rst : in std_logic;

    i_en       : in std_logic;
    i_write_en : in std_logic_vector(mem_word_count - 1 downto 0);
    i_addr     : in std_logic_vector(mem_addr_width_bytes - 1 downto 0);
    i_din      : in std_logic_vector(mem_data_width - 1 downto 0);
    o_dout     : out std_logic_vector(mem_data_width - 1 downto 0);

    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk    : in  std_logic;
    s00_axi_aresetn : in  std_logic;
    s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot  : in  std_logic_vector(2 downto 0);
    s00_axi_awvalid : in  std_logic;
    s00_axi_awready : out std_logic;
    s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid  : in  std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp   : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in  std_logic;
    s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot  : in  std_logic_vector(2 downto 0);
    s00_axi_arvalid : in  std_logic;
    s00_axi_arready : out std_logic;
    s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp   : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in  std_logic
  );
end acc_axi_top;

architecture arch_imp of acc_axi_top is

  constant mem_addr_width : integer := mem_addr_width_bytes - integer(ceil(log2(real(mem_word_count))));

  signal w_axi_rst,   w_axi_rstn  : std_logic;
  signal w_acc_rstn               : std_logic;
  signal w_axi_start, w_acc_start : std_logic;
  signal w_axi_done,  w_acc_done  : std_logic;

  signal w_params, r_params : parameters_t;
  signal w_status, r_status : status_info_t;

  signal w_mem_addr : std_logic_vector(mem_addr_width - 1 downto 0);

  attribute x_interface_mode      : string;
  attribute x_interface_info      : string;
  attribute x_interface_parameter : string;

  attribute x_interface_info      of s00_axi_aclk : signal is "xilinx.com:signal:clock:1.0 s00_axi_aclk CLK";
  attribute x_interface_parameter of s00_axi_aclk : signal is "ASSOCIATED_BUSIF s00_axi, ASSOCIATED_RESET s00_axi_aresetn"; --, FREQ_HZ 125000000

  attribute x_interface_parameter of clk_sp : signal is "XIL_INTERFACENAME scratchpad, MASTER_TYPE BRAM_CTRL, MEM_SIZE 2097152, MEM_WIDTH 64, MEM_ECC NONE, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1";

  attribute x_interface_mode of clk_sp      : signal is "Slave";
  attribute x_interface_info of clk_sp      : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad CLK";
  attribute x_interface_info of i_dummy_rst : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad RST";
  attribute x_interface_info of i_en        : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad EN";
  attribute x_interface_info of i_write_en  : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad WE";
  attribute x_interface_info of i_addr      : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad ADDR";
  attribute x_interface_info of i_din       : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad DIN";
  attribute x_interface_info of o_dout      : signal is "xilinx.com:interface:bram_rtl:1.0 scratchpad DOUT";

  attribute async_reg             : string;
  attribute async_reg of r_status : signal is "TRUE";
  attribute async_reg of r_params : signal is "TRUE";

begin

  w_axi_rstn <= not w_axi_rst;
  w_mem_addr <= i_addr(mem_addr_width_bytes - 1 downto mem_addr_width_bytes - mem_addr_width);

  -- Instantiation of AXI Bus Interface S00_AXI
  acc_axi_regs_inst : entity accel.acc_axi_regs generic map (
    C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH,
    size_x             => size_x,
    size_y             => size_y,
    line_length_iact   => line_length_iact,
    line_length_wght   => line_length_wght,
    line_length_psum   => line_length_psum,
    fifo_size_psum     => fifo_size_psum,
    data_width_iact    => data_width_input,
    data_width_wght    => data_width_input,
    data_width_psum    => data_width_psum,
    mem_addr_width     => mem_addr_width_bytes,
    mem_word_count     => mem_word_count,
    dataflow           => dataflow,
    postproc_enabled   => postproc_enabled
  ) port map (
    o_rst         => w_axi_rst,
    o_start       => w_axi_start,
    o_irq         => o_irq,
    i_done        => w_axi_done,
    o_params      => w_params,
    i_status      => r_status,
    S_AXI_ACLK    => s00_axi_aclk,
    S_AXI_ARESETN => s00_axi_aresetn,
    S_AXI_AWADDR  => s00_axi_awaddr,
    S_AXI_AWPROT  => s00_axi_awprot,
    S_AXI_AWVALID => s00_axi_awvalid,
    S_AXI_AWREADY => s00_axi_awready,
    S_AXI_WDATA   => s00_axi_wdata,
    S_AXI_WSTRB   => s00_axi_wstrb,
    S_AXI_WVALID  => s00_axi_wvalid,
    S_AXI_WREADY  => s00_axi_wready,
    S_AXI_BRESP   => s00_axi_bresp,
    S_AXI_BVALID  => s00_axi_bvalid,
    S_AXI_BREADY  => s00_axi_bready,
    S_AXI_ARADDR  => s00_axi_araddr,
    S_AXI_ARPROT  => s00_axi_arprot,
    S_AXI_ARVALID => s00_axi_arvalid,
    S_AXI_ARREADY => s00_axi_arready,
    S_AXI_RDATA   => s00_axi_rdata,
    S_AXI_RRESP   => s00_axi_rresp,
    S_AXI_RVALID  => s00_axi_rvalid,
    S_AXI_RREADY  => s00_axi_rready
  );

  accelerator_inst : entity accel.accelerator generic map (
    size_x           => size_x,
    size_y           => size_y,
    line_length_iact => line_length_iact,
    line_length_wght => line_length_wght,
    line_length_psum => line_length_psum,
    data_width_input => data_width_input,
    data_width_psum  => data_width_psum,
    mem_addr_width   => mem_addr_width,
    mem_word_count   => mem_word_count,
    mem_data_width   => mem_data_width,
    g_iact_fifo_size => fifo_size_iact,
    g_wght_fifo_size => fifo_size_wght,
    g_psum_fifo_size => fifo_size_psum,
    g_dataflow       => dataflow,
    use_float_ip     => use_float_ip,
    postproc_enable  => postproc_enabled
  ) port map (
    clk  => clk,
    rstn => w_acc_rstn,

    clk_sp => clk_sp,

    i_start  => w_acc_start,
    o_done   => w_acc_done,
    i_params => r_params,
    o_status => w_status,

    i_mem_en       => i_en,
    i_mem_write_en => i_write_en,
    i_mem_addr     => w_mem_addr,
    i_mem_din      => i_din,
    o_mem_dout     => o_dout
  );

  g_cdc : if axi_acc_cdc generate
  begin

    inst_sync_rst   : entity accel.bit_sync generic map (stages => 8) port map (clk, '0', w_axi_rstn,  w_acc_rstn);
    inst_sync_start : entity accel.bit_sync generic map (stages => 4) port map (clk, '0', w_axi_start, w_acc_start);
    inst_sync_done  : entity accel.bit_sync generic map (stages => 4) port map (s00_axi_aclk, '0', w_acc_done, w_axi_done);

  end generate;

  g_no_cdc : if not axi_acc_cdc generate
  begin

    w_acc_rstn <= w_axi_rstn;
    w_acc_start <= w_axi_start;
    w_axi_done <= w_acc_done;

  end generate;

  r_status <= w_status when rising_edge(s00_axi_aclk);
  r_params <= w_params when rising_edge(clk);

end arch_imp;
