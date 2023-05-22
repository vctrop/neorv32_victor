library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_top_wrapper is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 100000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 8*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    pwm_o       : out std_ulogic
  );
end entity;

architecture neorv32_top_wrapper_rtl of neorv32_top_wrapper is

  signal gpio_o_s : std_ulogic_vector(63 downto 0);
  signal uart0_cpu_tx_s : std_ulogic;
  signal uart0_cpu_rdy_s : std_ulogic;
  signal pwm_o_s : std_ulogic_vector(11 downto 0);
  
begin

  -- NEORV32 SoC core
  neorv32_top_inst: neorv32_top
  generic map(
    -- General --
    CLOCK_FREQUENCY              => CLOCK_FREQUENCY,    -- clock frequency of clk_i in Hz
    -- HART_ID                      => x"00000000",        -- hardware thread ID
    -- VENDOR_ID                    => x"00000000",        -- vendor's JEDEC ID
    -- CUSTOM_ID                    => x"00000000",        -- custom user-defined ID
    -- INT_BOOTLOADER_EN            => false,              -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM

    -- On-Chip Debugger (OCD) --
    -- ON_CHIP_DEBUGGER_EN          => false,

    -- RISC-V CPU Extensions --
    -- CPU_EXTENSION_RISCV_B        => false,  -- implement bit-manipulation extension?
    CPU_EXTENSION_RISCV_C        => true,  -- implement compressed extension?
    -- CPU_EXTENSION_RISCV_E        => false,  -- implement embedded RF extension?
    CPU_EXTENSION_RISCV_M        => true,  -- implement mul/div extension?
    -- CPU_EXTENSION_RISCV_U        => false,  -- implement user mode extension?
    CPU_EXTENSION_RISCV_Zfinx    => true,  -- implement 32-bit floating-point extension (using INT regs!)
    -- CPU_EXTENSION_RISCV_Zicntr   => true,   -- implement base counters?
    -- CPU_EXTENSION_RISCV_Zicond   => false,  -- implement conditional operations extension?
    -- CPU_EXTENSION_RISCV_Zihpm    => false,  -- implement hardware performance monitors?
    -- CPU_EXTENSION_RISCV_Zifencei => false,  -- implement instruction stream sync.?
    -- CPU_EXTENSION_RISCV_Zmmul    => false,  -- implement multiply-only M sub-extension?
    -- CPU_EXTENSION_RISCV_Zxcfu    => false,  -- implement custom (instr.) functions unit?

    -- Tuning Options --
    -- FAST_MUL_EN                  => false,  -- use DSPs for M extension's multiplier
    -- FAST_SHIFT_EN                => false,  -- use barrel shifter for shift operations
    -- CPU_IPB_ENTRIES              => 1,      -- entries in instruction prefetch buffer, has to be a power of 2, min 1

    -- Physical Memory Protection (PMP) --
    -- PMP_NUM_REGIONS              => 0,      -- number of regions (0..16)
    -- PMP_MIN_GRANULARITY          => 4,      -- minimal region granularity in bytes, has to be a power of 2, min 4 bytes

    -- Hardware Performance Monitors (HPM) --
    -- HPM_NUM_CNTS                 => 0,      -- number of implemented HPM counters (0..29)
    -- HPM_CNT_WIDTH                => 40,     -- total size of HPM counters (0..64)

    -- Internal Instruction memory (IMEM) --
    MEM_INT_IMEM_EN              => true,  -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => MEM_INT_IMEM_SIZE, -- size of processor-internal instruction memory in bytes

    -- Internal Data memory (DMEM) --
    MEM_INT_DMEM_EN              => true,  -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => MEM_INT_DMEM_SIZE, -- size of processor-internal data memory in bytes

    -- Internal Instruction Cache (iCACHE) --
    ICACHE_EN                    => true,  -- implement instruction cache
    -- ICACHE_NUM_BLOCKS            => 4,      -- i-cache: number of blocks (min 1), has to be a power of 2
    -- ICACHE_BLOCK_SIZE            => 64,     -- i-cache: block size in bytes (min 4), has to be a power of 2
    -- ICACHE_ASSOCIATIVITY         => 1,      -- i-cache: associativity / number of sets (1=direct_mapped), has to be a power of 2

    -- Internal Data Cache (dCACHE) --
    DCACHE_EN                    => true,  -- implement data cache
    -- DCACHE_NUM_BLOCKS            => 4,      -- d-cache: number of blocks (min 1), has to be a power of 2
    -- DCACHE_BLOCK_SIZE            => 64,     -- d-cache: block size in bytes (min 4), has to be a power of 2

    -- External memory interface (WISHBONE) --
    -- MEM_EXT_EN                   => false,  -- implement external memory bus interface?
    -- MEM_EXT_TIMEOUT              => 255,    -- cycles after a pending bus access auto-terminates (0 = disabled)
    -- MEM_EXT_PIPE_MODE            => false,  -- protocol: false=classic/standard wishbone mode, true=pipelined wishbone mode
    -- MEM_EXT_BIG_ENDIAN           => false,  -- byte order: true=big-endian, false=little-endian
    -- MEM_EXT_ASYNC_RX             => false,  -- use register buffer for RX data when false
    -- MEM_EXT_ASYNC_TX             => false,  -- use register buffer for TX data when false

    -- External Interrupts Controller (XIRQ) --
    -- XIRQ_NUM_CH                  => 0,      -- number of external IRQ channels (0..32)
    -- XIRQ_TRIGGER_TYPE            => x"ffffffff", -- trigger type: 0=level, 1=edge
    -- XIRQ_TRIGGER_POLARITY        => x"ffffffff", -- trigger polarity: 0=low-level/falling-edge, 1=high-level/rising-edge

    -- Processor peripherals --
    IO_GPIO_NUM                  => 8,      -- number of GPIO input/output pairs (0..64)
    IO_MTIME_EN                  => true,  -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true,  -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_UART0_RX_FIFO             => 1,      -- RX fifo depth, has to be a power of two, min 1
    IO_UART0_TX_FIFO             => 1,      -- TX fifo depth, has to be a power of two, min 1
    -- IO_UART1_EN                  => false,  -- implement secondary universal asynchronous receiver/transmitter (UART1)?
    -- IO_UART1_RX_FIFO             => 1,      -- RX fifo depth, has to be a power of two, min 1
    -- IO_UART1_TX_FIFO             => 1,      -- TX fifo depth, has to be a power of two, min 1
    -- IO_SPI_EN                    => false,  -- implement serial peripheral interface (SPI)?
    -- IO_SPI_FIFO                  => 1,      -- SPI RTX fifo depth, has to be a power of two, min 1
    -- IO_SDI_EN                    => false,  -- implement serial data interface (SDI)?
    -- IO_SDI_FIFO                  => 0,      -- SDI RTX fifo depth, has to be zero or a power of two
    -- IO_TWI_EN                    => false,  -- implement two-wire interface (TWI)?
    IO_PWM_NUM_CH                => 1      -- number of PWM channels to implement (0..12); 0 = disabled
    -- IO_WDT_EN                    => false,  -- implement watch dog timer (WDT)?
    -- IO_TRNG_EN                   => false,  -- implement true random number generator (TRNG)?
    -- IO_TRNG_FIFO                 => 1,      -- TRNG fifo depth, has to be a power of two, min 1
    -- IO_CFS_EN                    => false,  -- implement custom functions subsystem (CFS)?
    -- IO_CFS_CONFIG                => x"00000000", -- custom CFS configuration generic
    -- IO_CFS_IN_SIZE               => 32,     -- size of CFS input conduit in bits
    -- IO_CFS_OUT_SIZE              => 32,     -- size of CFS output conduit in bits
    -- IO_NEOLED_EN                 => false,  -- implement NeoPixel-compatible smart LED interface (NEOLED)?
    -- IO_NEOLED_TX_FIFO            => 1,      -- NEOLED FIFO depth, has to be a power of two, min 1
    -- IO_GPTMR_EN                  => false,  -- implement general purpose timer (GPTMR)?
    -- IO_XIP_EN                    => false,  -- implement execute in place module (XIP)?
    -- IO_ONEWIRE_EN                => false   -- implement 1-wire interface (ONEWIRE)?
  )
  port map(
    -- Global control --
    clk_i          => clk_i, -- global clock, rising edge
    rstn_i         => rstn_i, -- global reset, low-active, async

    -- GPIO (available if IO_GPIO_NUM > 0) --
    gpio_o         => gpio_o_s,       -- parallel output
    gpio_i         => (others => 'U'), -- parallel input
    
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o    => uart0_cpu_tx_s, -- UART0 send data
    uart0_rxd_i    => 'U', -- UART0 receive data
    uart0_rts_o    => uart0_cpu_rdy_s, -- HW flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i    => 'L', -- HW flow control: UART0.TX allowed to transmit, low-active, optional
    
    -- PWM (available if IO_PWM_NUM_CH > 0) --                          
    pwm_o          => pwm_o_s -- pwm channels
  );
  
  -- GPIO output --
  gpio_o <= gpio_o_s(7 downto 0);
  pwm_o <= pwm_o_s(0);

end architecture;
