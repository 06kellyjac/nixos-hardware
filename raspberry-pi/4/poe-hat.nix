{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.raspberry-pi."4".poe-hat;
in {
  options.hardware = {
    raspberry-pi."4".poe-hat = {
      enable = lib.mkEnableOption ''
        support for the Raspberry Pi POE Hat.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure for modesetting in the device tree
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-5.15.y/arch/arm/boot/dts/overlays/rpi-poe-overlay.dts
        {
          name = "rpi-poe-overlay";
          dtsText = ''
            /*
            * Overlay for the Raspberry Pi POE HAT.
            */
            /dts-v1/;
            /plugin/;

            / {
              compatible = "raspberrypi,4-model-b", "brcm,bcm2711";

              fragment@0 {
                target-path = "/";
                __overlay__ {
                  fan: pwm-fan {
                    compatible = "pwm-fan";
                    cooling-levels = <0 1 10 100 255>;
                    #cooling-cells = <2>;
                    pwms = <&fwpwm 0 80000>;
                  };
                };
              };

              fragment@1 {
                target = <&cpu_thermal>;
                __overlay__ {
                  trips {
                    trip0: trip0 {
                      temperature = <40000>;
                      hysteresis = <2000>;
                      type = "active";
                    };
                    trip1: trip1 {
                      temperature = <45000>;
                      hysteresis = <2000>;
                      type = "active";
                    };
                    trip2: trip2 {
                      temperature = <50000>;
                      hysteresis = <2000>;
                      type = "active";
                    };
                    trip3: trip3 {
                      temperature = <55000>;
                      hysteresis = <5000>;
                      type = "active";
                    };
                  };
                  cooling-maps {
                    map0 {
                      trip = <&trip0>;
                      cooling-device = <&fan 0 1>;
                    };
                    map1 {
                      trip = <&trip1>;
                      cooling-device = <&fan 1 2>;
                    };
                    map2 {
                      trip = <&trip2>;
                      cooling-device = <&fan 2 3>;
                    };
                    map3 {
                      trip = <&trip3>;
                      cooling-device = <&fan 3 4>;
                    };
                  };
                };
              };

              fragment@2 {
                target-path = "/__overrides__";
                params: __overlay__ {
                  poe_fan_temp0 =		<&trip0>,"temperature:0";
                  poe_fan_temp0_hyst =	<&trip0>,"hysteresis:0";
                  poe_fan_temp1 =		<&trip1>,"temperature:0";
                  poe_fan_temp1_hyst =	<&trip1>,"hysteresis:0";
                  poe_fan_temp2 =		<&trip2>,"temperature:0";
                  poe_fan_temp2_hyst =	<&trip2>,"hysteresis:0";
                  poe_fan_temp3 =		<&trip3>,"temperature:0";
                  poe_fan_temp3_hyst =	<&trip3>,"hysteresis:0";
                  poe_fan_i2c =		<&fwpwm>,"status=disabled",
                        <&poe_mfd>,"status=okay",
                        <&fan>,"pwms:0=",<&poe_mfd_pwm>;
                };
              };

              fragment@3 {
                target = <&firmware>;
                __overlay__ {
                  fwpwm: pwm {
                    compatible = "raspberrypi,firmware-poe-pwm";
                    #pwm-cells = <2>;
                  };
                };
              };

              fragment@4 {
                target = <&i2c0>;
                i2c_bus: __overlay__ {
                  #address-cells = <1>;
                  #size-cells = <0>;

                  poe_mfd: poe@51 {
                    compatible = "raspberrypi,poe-core";
                    reg = <0x51>;
                    status = "disabled";

                    poe_mfd_pwm: poe_pwm@f0 {
                      compatible = "raspberrypi,poe-pwm";
                      reg = <0xf0>;
                      status = "okay";
                      #pwm-cells = <2>;
                    };
                  };
                };
              };

              fragment@5 {
                target = <&i2c0if>;
                __dormant__ {
                  status = "okay";
                };
              };

              fragment@6 {
                target = <&i2c0mux>;
                __dormant__ {
                  status = "okay";
                };
              };

              __overrides__ {
                poe_fan_temp0 =		<&trip0>,"temperature:0";
                poe_fan_temp0_hyst =	<&trip0>,"hysteresis:0";
                poe_fan_temp1 =		<&trip1>,"temperature:0";
                poe_fan_temp1_hyst =	<&trip1>,"hysteresis:0";
                poe_fan_temp2 =		<&trip2>,"temperature:0";
                poe_fan_temp2_hyst =	<&trip2>,"hysteresis:0";
                poe_fan_temp3 =		<&trip3>,"temperature:0";
                poe_fan_temp3_hyst =	<&trip3>,"hysteresis:0";
                i2c =			<0>, "+5+6",
                      <&fwpwm>,"status=disabled",
                      <&i2c_bus>,"status=okay",
                      <&poe_mfd>,"status=okay",
                      <&fan>,"pwms:0=",<&poe_mfd_pwm>;
              };
            };
          '';
        }
      ];
    };
  };
}
