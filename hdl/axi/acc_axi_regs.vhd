library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

library accel;
use accel.utilities.all;

entity acc_axi_regs is
  generic (
    -- Users to add parameters here
    -- number of registers to present, rest is read 0 / writes ignored
    NUM_REGS : integer := 80;

    -- static accelerator hardware info
    size_x : positive := 5;
    size_y : positive := 5;

    line_length_iact : positive := 64;
    line_length_psum : positive := 128;
    line_length_wght : positive := 64;

    -- Width of the pe input/output data (weights, iacts, psums)
    data_width_iact : positive := 8;
    data_width_wght : positive := 8;
    data_width_psum : positive := 16;

    -- external addresses are byte wise
    mem_addr_width : positive := 18;

    dataflow         : integer := 0;
    postproc_enabled : boolean := true;
    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH : integer := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH : integer := 9
  );
  port (
    -- Users to add ports here
    o_rst    : out   std_logic;
    o_start  : out   std_logic;
    i_done   : in    std_logic;
    o_params : out   parameters_t;
    i_status : in    status_info_t;
    -- User ports ends

    -- Global Clock Signal
    S_AXI_ACLK : in std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN : in std_logic;
    -- Write address (issued by master, acceped by Slave)
    S_AXI_AWADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Write channel Protection type. This signal indicates the
    -- privilege and security level of the transaction, and whether
    -- the transaction is a data access or an instruction access.
    S_AXI_AWPROT : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that the master signaling
    -- valid write address and control information.
    S_AXI_AWVALID : in std_logic;
    -- Write address ready. This signal indicates that the slave is ready
    -- to accept an address and associated control signals.
    S_AXI_AWREADY : out std_logic;
    -- Write data (issued by master, acceped by Slave)
    S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Write strobes. This signal indicates which byte lanes hold
    -- valid data. There is one write strobe bit for each eight
    -- bits of the write data bus.
    S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    -- Write valid. This signal indicates that valid write
    -- data and strobes are available.
    S_AXI_WVALID : in std_logic;
    -- Write ready. This signal indicates that the slave
    -- can accept the write data.
    S_AXI_WREADY : out std_logic;
    -- Write response. This signal indicates the status
    -- of the write transaction.
    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the channel
    -- is signaling a valid write response.
    S_AXI_BVALID : out std_logic;
    -- Response ready. This signal indicates that the master
    -- can accept a write response.
    S_AXI_BREADY : in std_logic;
    -- Read address (issued by master, acceped by Slave)
    S_AXI_ARADDR : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Protection type. This signal indicates the privilege
    -- and security level of the transaction, and whether the
    -- transaction is a data access or an instruction access.
    S_AXI_ARPROT : in std_logic_vector(2 downto 0);
    -- Read address valid. This signal indicates that the channel
    -- is signaling valid read address and control information.
    S_AXI_ARVALID : in std_logic;
    -- Read address ready. This signal indicates that the slave is
    -- ready to accept an address and associated control signals.
    S_AXI_ARREADY : out std_logic;
    -- Read data (issued by slave)
    S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Read response. This signal indicates the status of the
    -- read transfer.
    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel is
    -- signaling the required read data.
    S_AXI_RVALID : out std_logic;
    -- Read ready. This signal indicates that the master can
    -- accept the read data and response information.
    S_AXI_RREADY : in std_logic
  );
end acc_axi_regs;

architecture arch_imp of acc_axi_regs is
  -- AXI4LITE signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  -- ADDR_LSB is used for addressing 32/64 bit registers/memories
  -- ADDR_LSB = 2 for 32 bits (n downto 2)
  -- ADDR_LSB = 3 for 64 bits (n downto 3)
  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := integer(ceil(log2(real(NUM_REGS))));
  ------------------------------------------------
  ---- Signals for user logic register space example
  --------------------------------------------------
  ---- Number of Slave Registers 32
  type reg_arr_t is array (0 to NUM_REGS-1) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_regs     : reg_arr_t;
  signal slv_reg_rden : std_logic;
  signal slv_reg_wren : std_logic;
  signal reg_data_out : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal byte_index   : integer;
  signal aw_en        : std_logic;

  constant MAGIC_REG_VALUE : std_logic_vector(31 downto 0) := x"41434303"; -- "ACC" + register set version
begin
  -- I/O Connections assignments

  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP   <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RDATA   <= axi_rdata;
  S_AXI_RRESP   <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;

  -- Implement axi_awready generation
  -- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
  -- de-asserted when reset is low.
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
        aw_en <= '1';
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
          -- slave is ready to accept write address when
          -- there is a valid write address and write data
          -- on the write address and data bus. This design
          -- expects no outstanding transactions.
             axi_awready <= '1';
             aw_en <= '0';
          elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
             aw_en <= '1';
             axi_awready <= '0';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement axi_awaddr latching
  -- This process is used to latch the address when both
  -- S_AXI_AWVALID and S_AXI_WVALID are valid.
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
          -- Write Address latching
          axi_awaddr <= S_AXI_AWADDR;
        end if;
      end if;
    end if;
  end process;

  -- Implement axi_wready generation
  -- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
  -- de-asserted when reset is low.
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_wready <= '0';
      else
        if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
            -- slave is ready to accept write data when
            -- there is a valid write address and write data
            -- on the write address and data bus. This design
            -- expects no outstanding transactions.
            axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement memory mapped register select and write logic generation
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  -- select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

  process (S_AXI_ACLK)
    variable loc_addr     : unsigned(OPT_MEM_ADDR_BITS - 1 downto 0);
    variable capabilities : unsigned(7 downto 0);

    -- grab some additional status signals from the hierarchy
    -- alias spad_iact_done is << signal ^.accelerator_inst.scratchpad_interface_inst.r_done_iact : std_logic >>;
    -- alias spad_wght_done is << signal ^.accelerator_inst.scratchpad_interface_inst.r_done_wght : std_logic >>;
    -- seems vivado can't handle ^ in hierarchical names, so get the signals from the status record
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        slv_regs <= (others => (others => '0'));
      else
        loc_addr := unsigned(axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS - 1 downto ADDR_LSB));
        if (slv_reg_wren = '1') then
          if to_integer(loc_addr) < NUM_REGS then
            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
              if (S_AXI_WSTRB(byte_index) = '1') then
                -- Respective byte enables are asserted as per write strobes
                slv_regs(to_integer(loc_addr))(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          else
            null; -- ignore writes outside of register bank
          end if;
        end if;

        -- drive read-only and static registers
        slv_regs(1)(0) <= i_done;
        slv_regs(1)(1) <= not i_done and not o_start; -- generate the "ready" bit from i_done and o_start
        slv_regs(1)(2) <= i_status.spadif.spad_iact_done;
        slv_regs(1)(3) <= i_status.spadif.spad_wght_done;
        slv_regs(1)(4) <= i_status.spadif.preload_fifos_done;

        -- debug status registers
        slv_regs(22) <= std_logic_vector(resize(i_status.cycle_counter, C_S_AXI_DATA_WIDTH));
        slv_regs(23)(0) <= i_status.spadif.spad_iact_full;
        slv_regs(23)(1) <= i_status.spadif.spad_iact_empty;
        slv_regs(23)(2) <= i_status.spadif.spad_wght_full;
        slv_regs(23)(3) <= i_status.spadif.spad_wght_empty;
        slv_regs(24) <= std_logic_vector(resize(i_status.spadif.psum_overflows, C_S_AXI_DATA_WIDTH));

        -- static hardware info registers
        capabilities := (
          0 => std_logic(to_unsigned(dataflow, 1)(0)),
          1 => to_stdlogic(postproc_enabled),
          others => '0'
        );
        slv_regs(25) <= std_logic_vector(resize(to_unsigned(size_y, 16) & to_unsigned(size_x, 16), C_S_AXI_DATA_WIDTH));
        slv_regs(26) <= std_logic_vector(resize(to_unsigned(line_length_wght, 16) & to_unsigned(line_length_iact, 16), C_S_AXI_DATA_WIDTH));
        slv_regs(27) <= std_logic_vector(resize(to_unsigned(line_length_psum, 16), C_S_AXI_DATA_WIDTH));
        slv_regs(28) <= std_logic_vector(resize(to_unsigned(data_width_psum, 8) & to_unsigned(data_width_wght, 8) & to_unsigned(data_width_iact, 8), C_S_AXI_DATA_WIDTH));
        slv_regs(29) <= std_logic_vector(resize(to_unsigned(spad_axi_addr_width_psum, 8) & to_unsigned(spad_axi_addr_width_wght, 8) & to_unsigned(spad_axi_addr_width_iact, 8), C_S_AXI_DATA_WIDTH));
        slv_regs(30) <= std_logic_vector(resize(capabilities & to_unsigned(max_output_channels, 8), C_S_AXI_DATA_WIDTH));

        slv_regs(31)(MAGIC_REG_VALUE'range) <= MAGIC_REG_VALUE;
      end if;
    end if;
  end process;

  -- Implement write response logic generation
  -- The write response and response valid signals are asserted by the slave
  -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
  -- This marks the acceptance of address and indicates the status of
  -- write transaction.

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00"; --need to work more on the responses
      else
        if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
          axi_bvalid <= '1';
          axi_bresp  <= "00";
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
          axi_bvalid <= '0';                                   -- (there is a possibility that bready is always asserted high)
        end if;
      end if;
    end if;
  end process;

  -- Implement axi_arready generation
  -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
  -- S_AXI_ARVALID is asserted. axi_awready is
  -- de-asserted when reset (active low) is asserted.
  -- The read address is also latched when S_AXI_ARVALID is
  -- asserted. axi_araddr is reset to zero on reset assertion.

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '1');
      else
        if (axi_arready = '0' and S_AXI_ARVALID = '1') then
          -- indicates that the slave has acceped the valid read address
          axi_arready <= '1';
          -- Read Address latching
          axi_araddr  <= S_AXI_ARADDR;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement axi_arvalid generation
  -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_ARVALID and axi_arready are asserted. The slave registers
  -- data are available on the axi_rdata bus at this instance. The
  -- assertion of axi_rvalid marks the validity of read data on the
  -- bus and axi_rresp indicates the status of read transaction.axi_rvalid
  -- is deasserted on reset (active low). axi_rresp and axi_rdata are
  -- cleared to zero on reset (active low).
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      else
        if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
          -- Valid read data is available at the read data bus
          axi_rvalid <= '1';
          axi_rresp  <= "00"; -- 'OKAY' response
        elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
          -- Read data is accepted by the master
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement memory mapped register select and read logic generation
  -- Slave register read enable is asserted when valid address is available
  -- and the slave is ready to accept the read address.
  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid);

  process (slv_regs, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
    variable loc_addr : unsigned(OPT_MEM_ADDR_BITS - 1 downto 0);
  begin
    -- Address decoding for reading registers
    loc_addr := unsigned(axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS - 1 downto ADDR_LSB));
    if to_integer(loc_addr) < NUM_REGS then
      reg_data_out <= slv_regs(to_integer(loc_addr));
    else
      reg_data_out <= (others => '0');
    end if;
  end process;

  -- Output register or memory read data
  process (S_AXI_ACLK) is
  begin
    if (rising_edge (S_AXI_ACLK)) then
      if ( S_AXI_ARESETN = '0' ) then
        axi_rdata  <= (others => '0');
      else
        if (slv_reg_rden = '1') then
          -- When there is a valid read address (S_AXI_ARVALID) with
          -- acceptance of read address by the slave (axi_arready),
          -- output the read dada
          -- Read address mux
          axi_rdata <= reg_data_out; -- register read data
        end if;
      end if;
    end if;
  end process;

  -- Add user logic here
  o_rst   <= slv_regs(0)(0);
  o_start <= slv_regs(0)(1);

  o_params.requant_enab <= slv_regs(0)(2) = '1';
  o_params.mode_act     <= mode_activation_t'val(to_integer(unsigned(slv_regs(0)(5 downto 3))));

  o_params.dataflow     <= dataflow;
  o_params.inputchs     <= to_integer(unsigned(slv_regs( 2)( 9 downto 0)));
  o_params.outputchs    <= to_integer(unsigned(slv_regs( 3)( 9 downto 0)));
  o_params.image_y      <= to_integer(unsigned(slv_regs( 4)(11 downto 0)));
  o_params.image_x      <= to_integer(unsigned(slv_regs( 5)(11 downto 0)));
  o_params.kernel_size  <= to_integer(unsigned(slv_regs( 6)( 4 downto 0)));
  o_params.c1           <= to_integer(unsigned(slv_regs( 7)( 9 downto 0)));
  o_params.w1           <= to_integer(unsigned(slv_regs( 8)( 9 downto 0)));
  o_params.h2           <= to_integer(unsigned(slv_regs( 9)( 9 downto 0)));
  o_params.m0           <= to_integer(unsigned(slv_regs(10)( 9 downto 0)));
  o_params.m0_last_m1   <= to_integer(unsigned(slv_regs(11)( 9 downto 0)));
  o_params.rows_last_h2 <= to_integer(unsigned(slv_regs(12)( 9 downto 0)));
  o_params.c0           <= to_integer(unsigned(slv_regs(13)( 9 downto 0)));
  o_params.c0_last_c1   <= to_integer(unsigned(slv_regs(14)( 9 downto 0)));
  o_params.c0w0         <= to_integer(unsigned(slv_regs(15)( 9 downto 0)));
  o_params.c0w0_last_c1 <= to_integer(unsigned(slv_regs(16)( 9 downto 0)));

  -- registers for bias, scale, zeropt per output channel, limited by maximum m0 value max_output_channels
  g_bias_req_regs : for x in 0 to max_output_channels - 1 generate
    o_params.bias(x)        <= to_integer(unsigned(slv_regs(32 + x)(15 downto 0)));
    o_params.scale_fp32(x)  <= slv_regs(32 + 1 * max_output_channels + x)(31 downto 0);
    o_params.zeropt_fp32(x) <= slv_regs(32 + 2 * max_output_channels + x)(31 downto 0);
  end generate g_bias_req_regs;
  -- User logic ends

end arch_imp;
