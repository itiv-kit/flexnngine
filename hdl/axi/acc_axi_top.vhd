library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library accel;
use accel.utilities.all;
use accel.sync.bit_sync;

entity acc_axi_top is
  generic (
    size_x : positive := 5;
    size_y : positive := 5;

    -- iact line buffer length & matching offset addressing width
    line_length_iact : positive := 64;
    addr_width_iact  : positive := 6;

    -- psum line buffer length & matching offset addressing width
    line_length_psum : positive := 128;
    addr_width_psum  : positive := 7;

    -- wght line buffer length & matching offset addressing width
    line_length_wght : positive := 64;
    addr_width_wght  : positive := 6;

    -- Width of the pe input/output data (weights, iacts, psums)
    data_width_iact : positive := 8;
    data_width_wght : positive := 8;
    data_width_psum : positive := 16;

    -- internal addresses are word wise (8 bit for iact/wght, 16 bit for psum)
    spad_addr_width_iact : positive := 16;
    spad_addr_width_wght : positive := 16;
    spad_addr_width_psum : positive := 16;

    -- external addresses are byte wise
    spad_axi_addr_width_iact : positive := 16;
    spad_axi_addr_width_wght : positive := 16;
    spad_axi_addr_width_psum : positive := 17;
    spad_ext_data_width_iact : positive := 32;
    spad_ext_data_width_wght : positive := 32;
    spad_ext_data_width_psum : positive := 32;

    dataflow             : integer := 0;
    postproc_enabled : boolean := true;

    -- enable cdc between AXI and accelerator clock domains if clocks differ
    axi_acc_cdc : boolean := false;

    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 7
  );
  port (
    clk    : in std_logic;
    clk_sp : in std_logic;

    -- unused clk/rst ports to make up a valid Vivado interface spec (VLNV)
    i_dummy_clk_iact : in std_logic;
    i_dummy_rst_iact : in std_logic;
    i_dummy_clk_wght : in std_logic;
    i_dummy_rst_wght : in std_logic;
    i_dummy_clk_psum : in std_logic;
    i_dummy_rst_psum : in std_logic;

    i_en_iact : in std_logic;
    i_en_wght : in std_logic;
    i_en_psum : in std_logic;

    i_write_en_iact : in std_logic_vector(spad_ext_data_width_iact/8 - 1 downto 0);
    i_write_en_wght : in std_logic_vector(spad_ext_data_width_wght/8 - 1 downto 0);
    i_write_en_psum : in std_logic_vector(spad_ext_data_width_psum/8 - 1 downto 0);

    -- external addresses are byte wise
    i_addr_iact : in std_logic_vector(spad_axi_addr_width_iact - 1 downto 0);
    i_addr_wght : in std_logic_vector(spad_axi_addr_width_wght - 1 downto 0);
    i_addr_psum : in std_logic_vector(spad_axi_addr_width_psum - 1 downto 0);

    i_din_iact : in std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
    i_din_wght : in std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
    i_din_psum : in std_logic_vector(spad_ext_data_width_psum - 1 downto 0);

    o_dout_iact : out std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
    o_dout_wght : out std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
    o_dout_psum : out std_logic_vector(spad_ext_data_width_psum - 1 downto 0);

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

  signal w_axi_rst,   w_axi_rstn  : std_logic;
  signal w_acc_rstn               : std_logic;
  signal w_axi_start, w_acc_start : std_logic;
  signal w_axi_done,  w_acc_done  : std_logic;

  signal w_params, r_params : parameters_t;
  signal w_status, r_status : status_info_t;

  attribute x_interface_mode      : string;
  attribute x_interface_info      : string;
  attribute x_interface_parameter : string;

  attribute x_interface_info      of s00_axi_aclk : signal is "xilinx.com:signal:clock:1.0 s00_axi_aclk CLK";
  attribute x_interface_parameter of s00_axi_aclk : signal is "ASSOCIATED_BUSIF s00_axi, ASSOCIATED_RESET s00_axi_aresetn, FREQ_HZ 100000000";

  attribute x_interface_parameter of i_dummy_clk_iact : signal is "XIL_INTERFACENAME bram_iact, MASTER_TYPE BRAM_CTRL, MEM_SIZE 65536, MEM_WIDTH 32, MEM_ECC NONE, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1";
  attribute x_interface_parameter of i_dummy_clk_wght : signal is "XIL_INTERFACENAME bram_wght, MASTER_TYPE BRAM_CTRL, MEM_SIZE 65536, MEM_WIDTH 32, MEM_ECC NONE, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1";
  attribute x_interface_parameter of i_dummy_clk_psum : signal is "XIL_INTERFACENAME bram_psum, MASTER_TYPE BRAM_CTRL, MEM_SIZE 131072, MEM_WIDTH 32, MEM_ECC NONE, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1";

  attribute x_interface_mode of i_dummy_clk_iact : signal is "Slave";
  attribute x_interface_info of i_dummy_clk_iact : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact CLK";
  attribute x_interface_info of i_dummy_rst_iact : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact RST";
  attribute x_interface_info of i_en_iact        : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact EN";
  attribute x_interface_info of i_write_en_iact  : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact WE";
  attribute x_interface_info of i_addr_iact      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact ADDR";
  attribute x_interface_info of i_din_iact       : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact DIN";
  attribute x_interface_info of o_dout_iact      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_iact DOUT";

  attribute x_interface_mode of i_dummy_clk_wght : signal is "Slave";
  attribute x_interface_info of i_dummy_clk_wght : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght CLK";
  attribute x_interface_info of i_dummy_rst_wght : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght RST";
  attribute x_interface_info of i_en_wght        : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght EN";
  attribute x_interface_info of i_write_en_wght  : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght WE";
  attribute x_interface_info of i_addr_wght      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght ADDR";
  attribute x_interface_info of i_din_wght       : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght DIN";
  attribute x_interface_info of o_dout_wght      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_wght DOUT";

  attribute x_interface_mode of i_dummy_clk_psum : signal is "Slave";
  attribute x_interface_info of i_dummy_clk_psum : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum CLK";
  attribute x_interface_info of i_dummy_rst_psum : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum RST";
  attribute x_interface_info of i_en_psum        : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum EN";
  attribute x_interface_info of i_write_en_psum  : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum WE";
  attribute x_interface_info of i_addr_psum      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum ADDR";
  attribute x_interface_info of i_din_psum       : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum DIN";
  attribute x_interface_info of o_dout_psum      : signal is "xilinx.com:interface:bram_rtl:1.0 bram_psum DOUT";

  attribute async_reg             : string;
  attribute async_reg of r_status : signal is "TRUE";
  attribute async_reg of r_params : signal is "TRUE";

begin

  w_axi_rstn <= not w_axi_rst;

  -- Instantiation of AXI Bus Interface S00_AXI
  acc_axi_regs_inst : entity accel.acc_axi_regs generic map (
    C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH,
    size_x => size_x,
    size_y => size_y,
    line_length_iact => line_length_iact,
    line_length_psum => line_length_psum,
    line_length_wght => line_length_wght,
    data_width_iact => data_width_iact,
    data_width_wght => data_width_wght,
    data_width_psum => data_width_psum,
    spad_axi_addr_width_iact => spad_axi_addr_width_iact,
    spad_axi_addr_width_wght => spad_axi_addr_width_wght,
    spad_axi_addr_width_psum => spad_axi_addr_width_psum,
    dataflow => dataflow,
    postproc_enabled => postproc_enabled
  ) port map (
    o_rst         => w_axi_rst,
    o_start       => w_axi_start,
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
    size_x    => size_x,
    size_y    => size_y,
    line_length_iact => line_length_iact,
    addr_width_iact => addr_width_iact,
    line_length_psum => line_length_psum,
    addr_width_psum => addr_width_psum,
    line_length_wght => line_length_wght,
    addr_width_wght => addr_width_wght,
    data_width_iact => data_width_iact,
    data_width_wght => data_width_wght,
    data_width_psum => data_width_psum,
    spad_addr_width_iact => spad_addr_width_iact,
    spad_addr_width_psum => spad_addr_width_psum,
    spad_addr_width_wght => spad_addr_width_wght,
    spad_ext_data_width_iact => spad_ext_data_width_iact,
    spad_ext_data_width_wght => spad_ext_data_width_wght,
    spad_ext_data_width_psum => spad_ext_data_width_psum,
    spad_ext_addr_width_iact => spad_axi_addr_width_iact - 2, -- convert byte-wise addresses to 32bit-word-wise
    spad_ext_addr_width_wght => spad_axi_addr_width_wght - 2, -- convert byte-wise addresses to 32bit-word-wise
    spad_ext_addr_width_psum => spad_axi_addr_width_psum - 2, -- convert byte-wise addresses to 32bit-word-wise
    g_dataflow => dataflow,
    g_en_postproc => postproc_enabled
  ) port map (
    clk  => clk,
    rstn => w_acc_rstn,

    clk_sp     => clk_sp,
    clk_sp_ext => s00_axi_aclk,

    i_start  => w_acc_start,
    o_done   => w_acc_done,
    i_params => r_params,
    o_status => w_status,

    i_en_iact => i_en_iact,
    i_en_wght => i_en_wght,
    i_en_psum => i_en_psum,

    i_write_en_iact => i_write_en_iact,
    i_write_en_wght => i_write_en_wght,
    i_write_en_psum => i_write_en_psum,

    i_addr_iact => i_addr_iact(spad_axi_addr_width_iact - 1 downto 2),
    i_addr_wght => i_addr_wght(spad_axi_addr_width_wght - 1 downto 2),
    i_addr_psum => i_addr_psum(spad_axi_addr_width_psum - 1 downto 2),

    i_din_iact => i_din_iact,
    i_din_wght => i_din_wght,
    i_din_psum => i_din_psum,

    o_dout_psum => o_dout_psum,
    o_dout_iact => o_dout_iact,
    o_dout_wght => o_dout_wght
  );

  g_cdc : if axi_acc_cdc generate
  begin

    inst_sync_rst   : entity accel.bit_sync port map (clk, '0', w_axi_rstn,  w_acc_rstn);
    inst_sync_start : entity accel.bit_sync port map (clk, '0', w_axi_start, w_acc_start);
    inst_sync_done  : entity accel.bit_sync port map (s00_axi_aclk, '0', w_acc_done, w_axi_done);

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
