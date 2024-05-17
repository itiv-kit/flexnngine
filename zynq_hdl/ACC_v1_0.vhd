library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library accel;
use accel.utilities.parameters_t;

entity ACC_v1_0 is
  generic (
    size_x : positive := 5;
    size_y : positive := 5;

    data_width_iact          : positive := 8; -- Width of the input data (weights, iacts)
    data_width_wght          : positive := 8;
    data_width_psum          : positive := 16;

    -- internal addresses are word wise (8 bit for iact/wght, 16 bit for psum)
    spad_addr_width_iact     : positive := 16;
    spad_addr_width_wght     : positive := 16;
    spad_addr_width_psum     : positive := 16;

    -- external addresses are byte wise
    spad_axi_addr_width_iact : positive := 16;
    spad_axi_addr_width_wght : positive := 16;
    spad_axi_addr_width_psum : positive := 17;
    spad_ext_data_width_iact : positive := 32;
    spad_ext_data_width_wght : positive := 32;
    spad_ext_data_width_psum : positive := 32;

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
end ACC_v1_0;

architecture arch_imp of ACC_v1_0 is
  component ACC_v1_0_S00_AXI is
    generic (
      NUM_REGS : integer := 32;
      C_S_AXI_DATA_WIDTH : integer := 32;
      C_S_AXI_ADDR_WIDTH : integer := 7
    );
    port (
      o_rst         : out   std_logic;
      o_start       : out   std_logic;
      i_done        : in    std_logic;
      o_params      : out   parameters_t;
      S_AXI_ACLK    : in std_logic;
      S_AXI_ARESETN : in std_logic;
      S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
      S_AXI_AWVALID : in std_logic;
      S_AXI_AWREADY : out std_logic;
      S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WVALID  : in std_logic;
      S_AXI_WREADY  : out std_logic;
      S_AXI_BRESP   : out std_logic_vector(1 downto 0);
      S_AXI_BVALID  : out std_logic;
      S_AXI_BREADY  : in std_logic;
      S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
      S_AXI_ARVALID : in std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP   : out std_logic_vector(1 downto 0);
      S_AXI_RVALID  : out std_logic;
      S_AXI_RREADY  : in std_logic
    );
  end component ACC_v1_0_S00_AXI;

  component accelerator is
    generic (
      size_x    : positive := 5;
      size_y    : positive := 5;
      size_rows : positive := 9;

      addr_width_rows : positive := 4;
      addr_width_y    : positive := 3;
      addr_width_x    : positive := 3;

      -- iact word size, pe line buffer length & matching offset addressing width
      data_width_iact     : positive := 8;
      line_length_iact    : positive := 512;
      addr_width_iact     : positive := 9;

      -- psum word size, pe line buffer length & matching offset addressing width
      data_width_psum     : positive := 16;
      line_length_psum    : positive := 1024;
      addr_width_psum     : positive := 10;

      -- wght word size, pe line buffer length & matching offset addressing width
      data_width_wght     : positive := 8;
      line_length_wght    : positive := 512;
      addr_width_wght     : positive := 9;

      -- address widths scratchpad <-> pe array
      spad_addr_width_iact : positive := 15; -- word size data_width_iact
      spad_addr_width_wght : positive := 15; -- word size data_width_wght
      spad_addr_width_psum : positive := 15; -- word size data_width_psum

      -- address widths scratchpad <-> external, port_a is exposed as i/o on this module
      spad_ext_addr_width_iact : positive := 13; -- word size spad_ext_data_width_iact
      spad_ext_addr_width_wght : positive := 13; -- word size spad_ext_data_width_wght
      spad_ext_addr_width_psum : positive := 14; -- word size spad_ext_data_width_psum
      spad_ext_data_width_iact : positive := 32;
      spad_ext_data_width_wght : positive := 32;
      spad_ext_data_width_psum : positive := 32;

      fifo_width : positive := 16;

      g_iact_fifo_size : positive := 15;
      g_wght_fifo_size : positive := 15;
      g_psum_fifo_size : positive := 45;

      g_files_dir : string  := "";
      g_init_sp   : boolean := false;
      g_dataflow  : integer := 1
    );
    port (
      clk  : in    std_logic;
      rstn : in    std_logic;

      clk_sp : in    std_logic;

      i_start  : in    std_logic;
      o_done   : out   std_logic;
      i_params : in    parameters_t;

      i_en_iact : in    std_logic;
      i_en_wght : in    std_logic;
      i_en_psum : in    std_logic;

      i_write_en_iact : in    std_logic_vector(spad_ext_data_width_iact/8 - 1 downto 0);
      i_write_en_wght : in    std_logic_vector(spad_ext_data_width_wght/8 - 1 downto 0);
      i_write_en_psum : in    std_logic_vector(spad_ext_data_width_psum/8 - 1 downto 0);

      i_addr_iact : in    std_logic_vector(spad_ext_addr_width_iact - 1 downto 0);
      i_addr_wght : in    std_logic_vector(spad_ext_addr_width_wght - 1 downto 0);
      i_addr_psum : in    std_logic_vector(spad_ext_addr_width_psum - 1 downto 0);

      i_din_iact : in    std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
      i_din_wght : in    std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
      i_din_psum : in    std_logic_vector(spad_ext_data_width_psum - 1 downto 0);

      o_dout_iact : out   std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
      o_dout_wght : out   std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
      o_dout_psum : out   std_logic_vector(spad_ext_data_width_psum - 1 downto 0)
    );
  end component;

  signal rst, rstn : std_logic;
  signal start     : std_logic;
  signal done      : std_logic;
  signal params    : parameters_t;

  attribute x_interface_mode      : string;
  attribute x_interface_info      : string;
  attribute x_interface_parameter : string;

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

begin

  rstn <= not rst;

-- Instantiation of AXI Bus Interface S00_AXI
  ACC_v1_0_S00_AXI_inst : ACC_v1_0_S00_AXI generic map (
    C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
  ) port map (
    o_rst         => rst,
    o_start       => start,
    i_done        => done,
    o_params      => params,
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

  accelerator_inst : accelerator generic map (
    size_x    => size_x,
    size_y    => size_y,
    size_rows => size_x + size_y - 1,
    data_width_psum => data_width_psum,
    data_width_iact => data_width_iact,
    data_width_wght => data_width_wght,
    spad_addr_width_iact => spad_addr_width_iact,
    spad_addr_width_psum => spad_addr_width_psum,
    spad_addr_width_wght => spad_addr_width_wght,
    spad_ext_data_width_iact => spad_ext_data_width_iact,
    spad_ext_data_width_wght => spad_ext_data_width_wght,
    spad_ext_data_width_psum => spad_ext_data_width_psum,
    spad_ext_addr_width_iact => spad_axi_addr_width_iact - 2, -- convert byte-wise addresses to 32bit-word-wise
    spad_ext_addr_width_wght => spad_axi_addr_width_wght - 2, -- convert byte-wise addresses to 32bit-word-wise
    spad_ext_addr_width_psum => spad_axi_addr_width_psum - 2  -- convert byte-wise addresses to 32bit-word-wise
  ) port map (
    clk  => clk,
    rstn => rstn,

    clk_sp => clk_sp,

    i_start  => start,
    o_done   => done,
    i_params => params,

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

end arch_imp;
