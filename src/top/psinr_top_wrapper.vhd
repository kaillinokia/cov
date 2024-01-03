------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.combiner_pkg.ALL;
USE work.psinr_pkg.ALL;
USE work.psinr_out_pkg.ALL;


ENTITY psinr_top_wrapper IS
    GENERIC
    (
        num_parallel_re  : natural := 4;
        fpga_opt_g       : natural := 1
    );
    PORT
    (
    --------------------------------------------------------------------------------------------------
    -- clock, reset
    --------------------------------------------------------------------------------------------------
    clk                         : IN     std_logic;
    arst_n                      : IN     std_logic;
    reset                       : IN     std_logic;
    --------------------------------------------------------------------------------------------------
    -- Comp Config input 
    --------------------------------------------------------------------------------------------------
    comb_cfg                    : IN     std_logic_vector(31 DOWNTO 0);
    comb_cfg_valid              : IN     std_logic;
    comb_cfg_ready              : OUT    std_logic;
    --------------------------------------------------------------------------------------------------
    -- Comb input 
    --------------------------------------------------------------------------------------------------
    comb_tvalid                 : IN     std_logic;
    comb_tdata                  : IN     std_logic_vector(num_parallel_re*15-1 DOWNTO 0);
    comb_texp                   : IN     std_logic_vector(num_parallel_re*8-1 DOWNTO 0);
    comb_tlast                  : IN     std_logic_vector(3 DOWNTO 0);
    comb_tready                 : OUT    std_logic;
    --------------------------------------------------------------------------------------------------
    -- Comp psinr output 
    --------------------------------------------------------------------------------------------------
    comb_psinr_tdata            : OUT    std_logic_vector(num_parallel_re*15-1 DOWNTO 0);
    comb_psinr_texp             : OUT    std_logic_vector(num_parallel_re*8-1 DOWNTO 0);
    comb_psinr_tvalid           : OUT    std_logic;
    comb_psinr_tlast            : OUT    std_logic_vector(3 DOWNTO 0);
    combiner_psinr_tre_rec      : OUT    std_logic_vector(14 DOWNTO 0);
    comb_psinr_tready           : OUT    std_logic;
    --------------------------------------------------------------------------------------------------
    -- Comp gain output 
    --------------------------------------------------------------------------------------------------
    comb_gain_tdata            : OUT     std_logic_vector(num_parallel_re*15-1 DOWNTO 0);
    comb_gain_texp             : OUT     std_logic_vector(num_parallel_re*8-1 DOWNTO 0);
    comb_gain_tvalid           : OUT     std_logic;
    comb_gain_tlast            : OUT     std_logic_vector(3 DOWNTO 0);
    comb_gain_tready           : IN      std_logic;
    --------------------------------------------------------------------------------------------------
    -- Comp status output 
    --------------------------------------------------------------------------------------------------
    comb_status_tvalid         : OUT     std_logic;
    comb_status_tdata          : OUT     std_logic_vector(11 DOWNTO 0);
    comb_status_tready         : IN      std_logic;
    --------------------------------------------------------------------------------------------------
    -- psinr Config input 
    --------------------------------------------------------------------------------------------------
    psinr_cfg_data              : IN     std_logic_vector(31 DOWNTO 0);
    psinr_cfg_valid             : IN     std_logic;
    psinr_cfg_ready             : OUT    std_logic; 
    --------------------------------------------------------------------------------------------------
    -- psinr demapper output 
    --------------------------------------------------------------------------------------------------
    psinr_layer_dmap_tdata    : OUT      std_logic_vector(16*num_parallel_re-1 DOWNTO 0);
    psinr_layer_dmap_tvalid   : OUT      std_logic;
    psinr_layer_dmap_tlast    : OUT      std_logic_vector(3 DOWNTO 0);
    psinr_layer_dmap_tready   : IN       std_logic; 
    --------------------------------------------------------------------------------------------------
    -- psinr  output 
    --------------------------------------------------------------------------------------------------  
    psinr_psinr_out_tdata     : OUT      std_logic_vector(15 DOWNTO 0);
    psinr_psinr_out_tvalid    : OUT      std_logic;
    psinr_psinr_out_tlast     : OUT      std_logic_vector(3 DOWNTO 0);
    psinr_psinr_out_tready    : OUT      std_logic;   
    --------------------------------------------------------------------------------------------------
    -- psinr demod  output 
    --------------------------------------------------------------------------------------------------
    psinr_dmod_tdata          : OUT    std_logic_vector(15 DOWNTO 0);
    psinr_dmod_tvalid         : OUT    std_logic;
    psinr_dmod_tlast          : OUT    std_logic_vector(3 DOWNTO 0);
    psinr_dmod_tready         : IN     std_logic;
    --------------------------------------------------------------------------------------------------
    -- psinr status output 
    --------------------------------------------------------------------------------------------------
    psinr_status_tvalid         : OUT     std_logic;
    psinr_status_tready         : IN      std_logic;
    psinr_status_tdata          : OUT     std_logic_vector(9 DOWNTO 0);
    --------------------------------------------------------------------------------------------------
    -- psinr out Config input 
    --------------------------------------------------------------------------------------------------
    psinr_out_cfg             : IN     std_logic_vector(31 DOWNTO 0);
    psinr_out_cfg_valid       : IN     std_logic;
    psinr_out_cfg_ready       : OUT    std_logic; 
    --------------------------------------------------------------------------------------------------
    -- psinr out UCI input 
    --------------------------------------------------------------------------------------------------
    UCI_ack_Psinr             : IN     std_logic_vector(255 DOWNTO 0);
    UCI_csi1_Psinr            : IN     std_logic_vector(255 DOWNTO 0);
    UCI_data_csi2_Psinr       : IN     std_logic_vector(255 DOWNTO 0);
    UCI_Psinr_out_valid       : IN     std_logic;
    psinr_out_UCI_tready      : OUT    std_logic; 
    --------------------------------------------------------------------------------------------------
    -- psinr out report
    --------------------------------------------------------------------------------------------------
    psinr_out_Report_tdata    : OUT    std_logic_vector(PSINR_OUT_OUT_WIDTH*num_parallel_re-1 DOWNTO 0);
    psinr_out_Report_tvalid   : OUT    std_logic;
    psinr_out_Report_tlast    : OUT    std_logic_vector(1 DOWNTO 0);
    psinr_out_Report_tready   : IN     std_logic;
    --------------------------------------------------------------------------------------------------
    -- psinr status output 
    --------------------------------------------------------------------------------------------------
    psinr_out_status_tvalid   : OUT     std_logic;
    psinr_out_status_tready   : IN      std_logic;
    psinr_out_status_tdata    : OUT     std_logic_vector(6 DOWNTO 0)

    );

END ENTITY psinr_top_wrapper;

--------------------------------------------------------------------------------
--  Architecture
--------------------------------------------------------------------------------

ARCHITECTURE str OF psinr_top_wrapper IS

----------------------------------------------------------------------------
-- Component declaration for 
----------------------------------------------------------------------------
    COMPONENT combiner_wrap IS
    GENERIC
    (
        num_parallel_re  : natural := 4;
        fpga_opt_g       : natural := 1
    );
    PORT
    (
      clk                         : IN      std_logic;
      arst_n                     : IN       std_logic;   --asic async reset
	    srst                       : IN       std_logic;   --FPGA sync reset
      -------------------------------------------------------------------
      -- combiner register interface
      -------------------------------------------------------------------
      combiner_cfg_data     : IN     cfg_bcomb_t;
	    combiner_cfg_valid    : IN     std_logic;
	    combiner_cfg_ready    : OUT    std_logic;
      ------------------------------------------------------------------------
      -- combiner input interface with iqfp
      ------------------------------------------------------------------------
      combiner_tvalid_i     : IN     std_logic;
      combiner_tlast_i      : IN     std_logic_vector(3 DOWNTO 0);
	    combiner_tdata_i      : IN     std_logic_vector(COMB_IN_WIDTH*num_parallel_re-1 DOWNTO 0);
	    combiner_texp_i       : IN     std_logic_vector(COMB_EXP_WIDTH*num_parallel_re-1 DOWNTO 0);
	    combiner_tready_o     : OUT    std_logic;
      ------------------------------------------------------------------------
      -- Interface with Psinr
      ------------------------------------------------------------------------
	    combiner_psinr_tvalid_o : OUT    std_logic;
	    combiner_psinr_tdata_o  : OUT    std_logic_vector(COMB_OUT_WIDTH*num_parallel_re-1 DOWNTO 0);
      combiner_psinr_texp_o   : OUT    std_logic_vector(COMB_EXP_WIDTH*num_parallel_re-1 DOWNTO 0);
	    combiner_psinr_tlast_o  : OUT    std_logic_vector(3 DOWNTO 0);
	    combiner_psinr_tready_i : IN     std_logic;
      combiner_psinr_tre_rec_o : OUT   std_logic_vector(14 DOWNTO 0);
	  ------------------------------------------------------------------------
      -- Interface with Gain Normalization
      ------------------------------------------------------------------------
	    combiner_gain_norm_tvalid_o : OUT    std_logic;
	    combiner_gain_norm_tdata_o  : OUT    std_logic_vector(COMB_OUT_WIDTH*num_parallel_re-1 DOWNTO 0);
      combiner_gain_norm_texp_o   : OUT    std_logic_vector(COMB_EXP_WIDTH*num_parallel_re-1 DOWNTO 0);
	    combiner_gain_norm_tlast_o  : OUT    std_logic_vector(3 DOWNTO 0);
	    combiner_gain_norm_tready_i : IN     std_logic;
      ------------------------------------------------------------------------
      -- Interface with debug block
      ---------------------- --------------------------------------------------
      combiner_busy_o             : OUT    std_logic;
	    m_combiner_status_tvalid_o  : OUT    std_logic;
      m_combiner_status_tdata_o   : OUT    stat_bcomb_t;
      m_combiner_status_tready_i  : IN     std_logic;
      dbg_combiner_o              : OUT    dbg_bcomb_t
    );
    END COMPONENT combiner_wrap;

    COMPONENT psinr_wrap IS
    GENERIC
    (
        num_parallel_re  : integer:= 4
    );
    PORT
    (
    clk                : IN     std_logic;
    arst_n             : IN     std_logic;   --asic async reset
		srst               : IN     std_logic;   --FPGA sync reset
    -------------------------------------------------------------------
    -- psinr register interface
    -------------------------------------------------------------------
    psinr_cfg_data     : IN     cfg_sinrc_t;
    psinr_cfg_valid    : IN     std_logic;
    psinr_cfg_ready    : OUT    std_logic;
    ------------------------------------------------------------------------
    -- combiner input interface with top level
    ------------------------------------------------------------------------
    psinr_comb_tvalid_i  : IN     std_logic;
    psinr_comb_tlast_i   : IN     std_logic_vector(3 DOWNTO 0);
    psinr_comb_tdata_i   : IN     std_logic_vector(PSINRC_IN_WIDTH*num_parallel_re-1 DOWNTO 0);
    psinr_comb_texp_i    : IN     std_logic_vector(PSINRC_EXP_WIDTH*num_parallel_re-1 DOWNTO 0);
    psinr_comb_tready_o  : OUT    std_logic;
    psinr_comb_tre_rec_i : IN     std_logic_vector(14 DOWNTO 0);
    ------------------------------------------------------------------------
    -- Interface with layer demapper
    ------------------------------------------------------------------------
    psinr_layer_dmap_tdata_o  : OUT    std_logic_vector(PSINRC_OUT_WIDTH*num_parallel_re-1 DOWNTO 0);
    psinr_layer_dmap_tvalid_o : OUT    std_logic;
    psinr_layer_dmap_tlast_o  : OUT    std_logic_vector(3 DOWNTO 0);
    psinr_layer_dmap_tready_i : IN     std_logic;
    ------------------------------------------------------------------------
    -- Interface with psinr out
    ------------------------------------------------------------------------
    psinr_psinr_out_tdata_o  : OUT    std_logic_vector(PSINRC_OUT_WIDTH-1 DOWNTO 0);
    psinr_psinr_out_tvalid_o : OUT    std_logic;
    psinr_psinr_out_tlast_o  : OUT    std_logic_vector(3 DOWNTO 0);
    psinr_psinr_out_tready_i : IN     std_logic;
    ------------------------------------------------------------------------
    -- Interface with dmod
    ------------------------------------------------------------------------
    psinr_dmod_tdata_o       : OUT    std_logic_vector(PSINRC_OUT_WIDTH-1 DOWNTO 0);
    psinr_dmod_tvalid_o      : OUT    std_logic;
    psinr_dmod_tlast_o       : OUT    std_logic_vector(3 DOWNTO 0);
    psinr_dmod_tready_i      : IN     std_logic;
    ------------------------------------------------------------------------
    -- Interface with debug block
    ---------------------- --------------------------------------------------
    psinr_busy_o             : OUT    std_logic;
    m_psinr_status_tvalid_o  : OUT    std_logic;
    m_psinr_status_tdata_o   : OUT    stat_sinrc_t;
    m_psinr_status_tready_i  : IN     std_logic;
		dbg_psinr_o              : OUT    dbg_sinrc_t
    );
    END COMPONENT psinr_wrap;

    COMPONENT psinr_out_wrap IS
    GENERIC
    (
        num_parallel_re  : integer:= 4
    );
    PORT
    (
      clk                : IN     std_logic;
      arst_n             : IN     std_logic;   --asic async reset
		  srst               : IN     std_logic;   --FPGA sync reset
      -------------------------------------------------------------------
      -- psinr_out register interface
      -------------------------------------------------------------------
      psinr_out_cfg_data     : IN     cfg_sinro_t;
      psinr_out_cfg_valid    : IN     std_logic;
      psinr_out_cfg_ready    : OUT    std_logic;
      ------------------------------------------------------------------------
      -- combiner input interface with top level
      ------------------------------------------------------------------------
      psinr_out_tvalid_i  : IN     std_logic;
      psinr_out_tlast_i   : IN     std_logic_vector(3 DOWNTO 0);
      psinr_out_tdata_i   : IN     std_logic_vector(15 DOWNTO 0);
      psinr_out_tready_o  : OUT    std_logic;
      ------------------------------------------------------------------------
      -- psinr out input interface with UCI
      ------------------------------------------------------------------------
      psinr_out_uci_tvalid_i  : IN     std_logic;
      psinr_out_uci_ack_i     : IN     std_logic_vector(PSINR_OUT_UCI_WIDTH-1 DOWNTO 0);
      psinr_out_uci_csi1_i    : IN     std_logic_vector(PSINR_OUT_UCI_WIDTH-1 DOWNTO 0);
      psinr_out_uci_csi2_i    : IN     std_logic_vector(PSINR_OUT_UCI_WIDTH-1 DOWNTO 0);
      psinr_out_uci_tready_o  : OUT    std_logic;
          
      ------------------------------------------------------------------------
      -- Interface with report
      ------------------------------------------------------------------------
      psinr_out_report_tdata_o       : OUT    std_logic_vector(PSINR_OUT_OUT_WIDTH*num_parallel_re-1 DOWNTO 0);
      psinr_out_report_tvalid_o      : OUT    std_logic;
      psinr_out_report_tlast_o       : OUT    std_logic_vector(1 DOWNTO 0);
      psinr_out_report_tready_i      : IN     std_logic;
      ------------------------------------------------------------------------
      -- Interface with debug block
      ---------------------- --------------------------------------------------
      psinr_out_busy_o             : OUT    std_logic;
      m_psinr_out_status_tvalid_o  : OUT    std_logic;
      m_psinr_out_status_tdata_o   : OUT    stat_sinro_t;
      m_psinr_out_status_tready_i  : IN     std_logic;
      dbg_psinr_out_o              : OUT    dbg_sinro_t
    );
    END COMPONENT psinr_out_wrap;

    signal   beta_cfg_info         : cfg_bcomb_t;
    signal   psinr_cfg_info        : cfg_sinrc_t;
    signal   psinr_out_cfg_info    : cfg_sinro_t;
    -- signal   comb_status_tready_int: std_logic;
    -- signal   psinr_status_tready_int: std_logic;
    -- signal   psinr_out_status_tready_int: std_logic;
    signal   psinr_comb_tready     : std_logic;
    signal   psinr_comb_tdata      : std_logic_vector(num_parallel_re*15-1 DOWNTO 0);
    signal   psinr_comb_texp       : std_logic_vector(num_parallel_re*8-1 DOWNTO 0);
    signal   psinr_comb_tvalid     : std_logic;
    signal   psinr_comb_tlast      : std_logic_vector(3 DOWNTO 0);

    signal   psinr_out_tdata       : std_logic_vector(15 DOWNTO 0);
    signal   psinr_out_tvalid      : std_logic;
    signal   psinr_out_tlast       : std_logic_vector(3 DOWNTO 0);
    signal   psinr_out_tready      : std_logic;   

    signal  comb_status_tdata_int  : stat_bcomb_t;
    signal  psinr_status_tdata_int : stat_sinrc_t;
    signal  psinr_out_status_tdata_int  : stat_sinro_t;

    signal  comb_psinr_tvalid_int  : std_logic;
    signal  comb_psinr_tlast_int   : std_logic_vector(3 DOWNTO 0);
    signal  comb_psinr_tdata_int   : std_logic_vector(num_parallel_re*15-1 DOWNTO 0);
    signal  comb_psinr_texp_int    : std_logic_vector(num_parallel_re*8-1 DOWNTO 0);
    signal  combiner_psinr_tre_rec_int : std_logic_vector(14 DOWNTO 0);
    signal  psinr_psinr_out_tdata_int  : std_logic_vector(15 DOWNTO 0);
    signal  psinr_psinr_out_tvalid_int : std_logic;
    signal  psinr_psinr_out_tlast_int  : std_logic_vector(3 DOWNTO 0);


BEGIN

    -- comb_status_tready_int <= '1';
    -- psinr_status_tready_int <= '1';
    -- psinr_out_status_tready_int <= '1';

    -- comb_status_tready <= comb_status_tready_int;
    -- psinr_status_tready <= psinr_status_tready_int;
    -- psinr_out_status_tready <= psinr_out_status_tready_int;

    comb_psinr_tvalid <= comb_psinr_tvalid_int;
    comb_psinr_tlast <= comb_psinr_tlast_int;
    comb_psinr_tdata <= comb_psinr_tdata_int;                            
    comb_psinr_texp  <= comb_psinr_texp_int;  
    combiner_psinr_tre_rec <= combiner_psinr_tre_rec_int;  
    
    psinr_psinr_out_tdata  <= psinr_psinr_out_tdata_int;
    psinr_psinr_out_tvalid <= psinr_psinr_out_tvalid_int;
    psinr_psinr_out_tlast  <= psinr_psinr_out_tlast_int;

    comb_psinr_tready <= psinr_comb_tready;
    psinr_psinr_out_tready <= psinr_out_tready;



    comb_status_tdata(0) <= comb_status_tdata_int.cfg_sprd_tp_err;
    comb_status_tdata(1) <= comb_status_tdata_int.cfg_sprd_seq_err;
    comb_status_tdata(2) <= comb_status_tdata_int.cfg_dr_md_err;
    comb_status_tdata(3) <= comb_status_tdata_int.cfg_layer_err;
    comb_status_tdata(4) <= comb_status_tdata_int.cfg_rb_err;
    comb_status_tdata(5) <= comb_status_tdata_int.cfg_sym_err;
    comb_status_tdata(6) <= comb_status_tdata_int.config_err;
    comb_status_tdata(7) <= comb_status_tdata_int.fifo_underflow;
    comb_status_tdata(8) <= comb_status_tdata_int.fifo_overflow;
    comb_status_tdata(9) <= comb_status_tdata_int.layer_mismatch;
    comb_status_tdata(10) <= comb_status_tdata_int.rb_mismatch;
    comb_status_tdata(11) <= comb_status_tdata_int.sym_mismatch;

    psinr_status_tdata(0) <= psinr_status_tdata_int.cfg_dr_md_err;
    psinr_status_tdata(1) <= psinr_status_tdata_int.cfg_layer_err;
    psinr_status_tdata(2) <= psinr_status_tdata_int.cfg_rb_err;
    psinr_status_tdata(3) <= psinr_status_tdata_int.cfg_sym_err;
    psinr_status_tdata(4) <= psinr_status_tdata_int.config_err;
    psinr_status_tdata(5) <= psinr_status_tdata_int.fifo_underflow;
    psinr_status_tdata(6) <= psinr_status_tdata_int.fifo_overflow;
    psinr_status_tdata(7) <= psinr_status_tdata_int.layer_mismatch;
    psinr_status_tdata(8) <= psinr_status_tdata_int.rb_mismatch;
    psinr_status_tdata(9) <= psinr_status_tdata_int.sym_mismatch;

    psinr_out_status_tdata(0) <= psinr_out_status_tdata_int.cfg_dr_md_err;
    psinr_out_status_tdata(1) <= psinr_out_status_tdata_int.cfg_layer_err;
    psinr_out_status_tdata(2) <= psinr_out_status_tdata_int.cfg_sym_err;
    psinr_out_status_tdata(3) <= psinr_out_status_tdata_int.config_err;
    psinr_out_status_tdata(4) <= psinr_out_status_tdata_int.layer_mismatch;
    psinr_out_status_tdata(5) <= psinr_out_status_tdata_int.rb_mismatch;
    psinr_out_status_tdata(6) <= psinr_out_status_tdata_int.sym_mismatch;

    u_combiner  : combiner_wrap
      GENERIC MAP
      (
        num_parallel_re => num_parallel_re,
        fpga_opt_g      => fpga_opt_g 
      )
    PORT MAP
    (
      clk                           => clk                , 
      arst_n                        => arst_n             , 
      srst                          => reset              ,
      combiner_cfg_data             => beta_cfg_info      , 
      combiner_cfg_valid            => comb_cfg_valid     , 
      combiner_cfg_ready            => comb_cfg_ready     , 
      combiner_tvalid_i             => comb_tvalid        , 
      combiner_tlast_i              => comb_tlast         , 
      combiner_tdata_i              => comb_tdata         , 
      combiner_texp_i               => comb_texp          , 
      combiner_tready_o             => comb_tready        , 
      combiner_psinr_tvalid_o       => comb_psinr_tvalid_int  , 
      combiner_psinr_tdata_o        => comb_psinr_tdata_int   , 
      combiner_psinr_texp_o         => comb_psinr_texp_int    ,
      combiner_psinr_tlast_o        => comb_psinr_tlast_int   , 
      combiner_psinr_tready_i       => psinr_comb_tready  , 
      combiner_psinr_tre_rec_o      => combiner_psinr_tre_rec_int,
      combiner_gain_norm_tvalid_o   => comb_gain_tvalid   , 
      combiner_gain_norm_tdata_o    => comb_gain_tdata    , 
      combiner_gain_norm_texp_o     => comb_gain_texp     ,
      combiner_gain_norm_tlast_o    => comb_gain_tlast    , 
      combiner_gain_norm_tready_i   => comb_gain_tready   ,
      combiner_busy_o               => open               ,
      m_combiner_status_tvalid_o    => comb_status_tvalid ,
      m_combiner_status_tdata_o     => comb_status_tdata_int  ,
      m_combiner_status_tready_i    => comb_status_tready ,
      dbg_combiner_o                => open        
    );

    u_psinr_calc  : psinr_wrap
    GENERIC MAP
    (
        num_parallel_re => num_parallel_re  
    )
    PORT MAP
    (
        clk                         => clk                      ,            
        arst_n                      => arst_n                   , 
        srst                        => reset                    ,                     
        psinr_cfg_data              => psinr_cfg_info           ,
        psinr_cfg_valid             => psinr_cfg_valid          ,
        psinr_cfg_ready             => psinr_cfg_ready          ,
        psinr_comb_tvalid_i         => comb_psinr_tvalid_int    ,
        psinr_comb_tlast_i          => comb_psinr_tlast_int       ,
        psinr_comb_tdata_i          => comb_psinr_tdata_int       ,
        psinr_comb_texp_i           => comb_psinr_texp_int        ,
        psinr_comb_tready_o         => psinr_comb_tready      ,
        psinr_comb_tre_rec_i        => combiner_psinr_tre_rec_int ,
        psinr_layer_dmap_tdata_o    => psinr_layer_dmap_tdata ,
        psinr_layer_dmap_tvalid_o   => psinr_layer_dmap_tvalid,
        psinr_layer_dmap_tlast_o    => psinr_layer_dmap_tlast ,
        psinr_layer_dmap_tready_i   => psinr_layer_dmap_tready,
        psinr_psinr_out_tdata_o     => psinr_psinr_out_tdata_int  ,
        psinr_psinr_out_tvalid_o    => psinr_psinr_out_tvalid_int ,
        psinr_psinr_out_tlast_o     => psinr_psinr_out_tlast_int  ,
        psinr_psinr_out_tready_i    => psinr_out_tready       ,
        psinr_dmod_tdata_o          => psinr_dmod_tdata       ,
        psinr_dmod_tvalid_o         => psinr_dmod_tvalid      ,
        psinr_dmod_tlast_o          => psinr_dmod_tlast       ,
        psinr_dmod_tready_i         => psinr_dmod_tready      ,
        psinr_busy_o                => open                   ,
        m_psinr_status_tvalid_o     => psinr_status_tvalid    ,
        m_psinr_status_tdata_o      => psinr_status_tdata_int ,
        m_psinr_status_tready_i     => psinr_status_tready    ,
        dbg_psinr_o                 => open     
    );

    u_psinr_out  : psinr_out_wrap
    GENERIC MAP
    (
        num_parallel_re => num_parallel_re  
    )
    PORT MAP
    (
      clk                          => clk,                          
      arst_n                      => arst_n                   , 
      srst                        => reset                    ,   
      psinr_out_cfg_data           => psinr_out_cfg_info,                      
      psinr_out_cfg_valid          => psinr_out_cfg_valid,                      
      psinr_out_cfg_ready          => psinr_out_cfg_ready,                      
      psinr_out_tvalid_i           => psinr_psinr_out_tvalid_int,                     
      psinr_out_tlast_i            => psinr_psinr_out_tlast_int,                     
      psinr_out_tdata_i            => psinr_psinr_out_tdata_int,                     
      psinr_out_tready_o           => psinr_out_tready,                     
      psinr_out_uci_tvalid_i       => UCI_Psinr_out_valid,                      
      psinr_out_uci_ack_i          => UCI_ack_Psinr   ,                      
      psinr_out_uci_csi1_i         => UCI_csi1_Psinr ,                      
      psinr_out_uci_csi2_i         => UCI_data_csi2_Psinr,                      
      psinr_out_uci_tready_o       => psinr_out_UCI_tready,                      
      psinr_out_report_tdata_o     => psinr_out_Report_tdata ,                            
      psinr_out_report_tvalid_o    => psinr_out_Report_tvalid,                            
      psinr_out_report_tlast_o     => psinr_out_Report_tlast ,                            
      psinr_out_report_tready_i    => psinr_out_Report_tready,                            
      psinr_out_busy_o             => open,                            
      m_psinr_out_status_tvalid_o  => psinr_out_status_tvalid,                       
      m_psinr_out_status_tdata_o   => psinr_out_status_tdata_int,                       
      m_psinr_out_status_tready_i  => psinr_out_status_tready,
      dbg_psinr_out_o              => open                       
    );

    -- psinr_comb_tdata  <= comb_psinr_tdata ;
    -- psinr_comb_texp   <= comb_psinr_texp  ;
    -- psinr_comb_tvalid <= comb_psinr_tvalid;
    -- psinr_comb_tlast  <= comb_psinr_tlast ;

    -- psinr_out_tdata   <= psinr_psinr_out_tdata ; 
    -- psinr_out_tvalid  <= psinr_psinr_out_tvalid;
    -- psinr_out_tlast   <= psinr_psinr_out_tlast ;


    beta_cfg_info.pucch_f2_flag <= comb_cfg(0);
    beta_cfg_info.pucch_spread_type <= comb_cfg(2 DOWNTO 1);
    beta_cfg_info.pucch_spread_seq_id <= comb_cfg(5 DOWNTO 3);
    beta_cfg_info.num_layer <= comb_cfg(9 DOWNTO 6);
    beta_cfg_info.num_sym <= comb_cfg(13 DOWNTO 10);
    beta_cfg_info.num_rb <= comb_cfg(22 DOWNTO 14); 
    beta_cfg_info.processing_type <= comb_cfg(26 DOWNTO 23);
    beta_cfg_info.du_ru_mode <= comb_cfg(29 DOWNTO 27);

    psinr_cfg_info.configured_sinr <= psinr_cfg_data(4 DOWNTO 0);
    psinr_cfg_info.sinr_calculation_bypass <= psinr_cfg_data(5);
    psinr_cfg_info.su_mu_mode <= psinr_cfg_data(6);
    psinr_cfg_info.pucch_f2_flag <= psinr_cfg_data(7);
    psinr_cfg_info.num_layer <= psinr_cfg_data(11 DOWNTO 8);
    psinr_cfg_info.num_sym <= psinr_cfg_data(15 DOWNTO 12);
    psinr_cfg_info.num_rb <= psinr_cfg_data(24 DOWNTO 16); 
    psinr_cfg_info.processing_type <= psinr_cfg_data(28 DOWNTO 25); 
    psinr_cfg_info.du_ru_mode <= psinr_cfg_data(31 DOWNTO 29); 

    psinr_out_cfg_info.num_sym <= psinr_out_cfg(3 DOWNTO 0);
    psinr_out_cfg_info.num_layer <= psinr_out_cfg(7 DOWNTO 4);
    psinr_out_cfg_info.processing_type <= psinr_out_cfg(11 DOWNTO 8);
    psinr_out_cfg_info.du_ru_mode <= psinr_out_cfg(14 DOWNTO 12);


END ARCHITECTURE str;