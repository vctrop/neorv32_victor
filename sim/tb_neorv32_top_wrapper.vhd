library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library neorv32;
use neorv32.neorv32_package.all;

entity tb_neorv32_top_wrapper is
--  Port ( );
end tb_neorv32_top_wrapper;

architecture Behavioral of tb_neorv32_top_wrapper is
  signal clk_gen_s : std_ulogic := '0';
  signal rst_gen_s : std_ulogic := '1';
  signal gpio_8bit_s : std_ulogic_vector(7 downto 0);
  signal xirq_8bit_s : std_ulogic_vector(7 downto 0);
  signal pwm_o_s : std_ulogic;
  
  constant f_clock_c : natural := 100000000;
  constant t_clock_c : time := (1 sec) / f_clock_c;
  
  component neorv32_top_wrapper is
  port (
    clk_i   : in std_ulogic;
    rstn_i  : in std_ulogic;
    xirq_i  : in std_ulogic_vector(7 downto 0);
    gpio_o  : out std_ulogic_vector(7 downto 0);
    pwm_o   : out std_ulogic
  );
  end component;
  
begin

  clk_gen_s <= not clk_gen_s after (t_clock_c/2);
  rst_gen_s <= '0', '1' after 60 * (t_clock_c/2);

  neorv32_top_wrapper_inst: neorv32_top_wrapper
  port map (
    clk_i   => clk_gen_s,
    rstn_i  => rst_gen_s,
    xirq_i  => xirq_8bit_s,
    gpio_o  => gpio_8bit_s,
    pwm_o   => pwm_o_s
  );

  xirq_8bit_s <= gpio_8bit_s;

end Behavioral;
