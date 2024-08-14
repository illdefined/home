{ config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  cmd = {
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    fish = "${osConfig.programs.fish.package}/bin/fish";
    grim = "${pkgs.grim}/bin/grim";
    jq = "${config.programs.jq.package}/bin/jq";
    keepassxc = "${pkgs.keepassxc}/bin/keepassxc";
    kitty = ''${config.programs.kitty.package}/bin/kitty --single-instance --instance-group "$XDG_SESSION_ID"'';
    loginctl = "${osConfig.systemd.package}/bin/loginctl";
    mpv = "${config.programs.mpv.package}/bin/mpv";
    pidof = "${pkgs.procps}/bin/pidof";
    playerctl = "${pkgs.playerctl}/bin/playerctl";
    slurp = "${pkgs.slurp}/bin/slurp";
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    wpctl = "${osConfig.services.pipewire.wireplumber.package}/bin/wpctl";
    xdg-open = "${pkgs.xdg-utils}/bin/xdg-open";
  };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  home.file.".xkb/symbols/greedy".source = ./greedy.xkb;

  home.keyboard = {
    layout = "greedy";
    options = [ "ctrl:nocaps" ];
  };

  home.packages = with pkgs; [
    # Image processing
    oxipng

    # Documentation
    linux-manual
    man-pages
    man-pages-posix

    # System operations
    restic

    # Cryptography
    age

    # Messaging
    element-desktop
    signal-desktop

    # Audio control
    pwvucontrol

    evince
    inkscape
    obsidian

    kicad
    calibre
    #enpass
    keepassxc

    # fonts
    fira-code
    font-awesome
    lato

    # Multimedia
    jellyfin-mpv-shim

    libreoffice
  ];

  fonts.fontconfig.enable = true;

  programs.beets = {
    enable = true;
    settings = {
      directory = "~/msc";
      import.reflink = "auto";

      plugins = [
        "chroma"
        "spotify"
        "fromfilename"

        "fetchart"
        "lyrics"
        "replaygain"

        "duplicates"
        "hook"
      ];

      hook.hooks = [
        {
          event = "import";
          command = "systemctl --user start mopidy-scan.service";
        }
      ];
    };
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "5x3";
      grace = 2;
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      background = {
        path = "screenshot";
        blur_passes = 3;
        contrast = 1.25;
      };
    };
  };

  programs.imv.enable = true;

  programs.kitty =
  let
    font-features = "+ss01 +ss06 +zero +onum";
  in {
    enable = true;
    theme = "Catppuccin-Mocha";
    settings = {
      disable_ligatures = "cursor";
      "font_features FiraCodeRoman_400wght" = font-features;
      "font_features FiraCodeRoman_500wght" = font-features;
      "font_features FiraCodeRoman_600wght" = font-features;
      "font_features FiraCodeRoman_700wght" = font-features;

      cursor_blink_interval = 0;

      scrollback_lines = 65536;

      enable_audio_bell = false;

      close_on_child_death = true;

      clear_all_shortcuts = true;
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "shift+insert" = "paste_from_selection";
      "ctrl+up" = "scroll_line_up";
      "ctrl+down" = "scroll_line_down";
      "ctrl+page_up" = "scroll_page_up";
      "ctrl+page_down" = "scroll_page_down";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "ctrl+home" = "scroll_home";
      "ctrl+end" = "scroll_end";
      "ctrl+print_screen" = "show_scrollback";

      "ctrl+equal" = "change_font_size all 0";
      "ctrl+plus" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";

      "ctrl+shift+u" = "kitten unicode_input";
    };
  };

  programs.mpv = {
    enable = true;
    defaultProfiles = [ "high-quality" ];
    config = {
      #access-references = false;

      # video output
      vo = "gpu";
      #gpu-api = "vulkan";
      hwdec = "vulkan,vaapi,auto-safe";
      vd-lavc-dr = true;

      scale = "ewa_lanczos4sharpest";
      cscale = "spline64";
      dscale = "mitchell";
      tscale = "oversample";

      # A/V sync
      video-sync = "display-resample";
      interpolation = true;

      # audio
      volume = 100;
      volume-max = 100;

      # subtitles
      sub-auto = "fuzzy";

      # screenshots
      screenshot-format = "avif";

      # cache
      demuxer-max-bytes = "768MiB";
      demuxer-max-back-bytes = "256MiB";
    };

    profiles = {
      highres = {
        scale = "spline64";
      };
    };

    scripts = with pkgs.mpvScripts; [
      mpris
      autocrop
      autodeint
    ];

    scriptOpts = {
      autocrop.auto = false;
    };
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit (tpkgs) 
        texlive-scripts

        xelatex-dev
        fontspec
        polyglossia

        hyphen-english
        hyphen-french
        hyphen-german
        hyphen-portuguese
        hyphen-spanish

        koma-script

        amsmath
        bookmark
        booktabs
        csquotes
        hyperref
        multirow
        paralist
        preprint
        realscripts
        textpos
        unicode-math
        units
        xecjk
        xecolor
        xltxtra
        xtab
      ;
    };
  };

  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;
    profiles = { };
  };

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        spacing = 4;
        modules-left = [ "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "tray" "network" "pulseaudio" "backlight" "battery" "temperature" "cpu" "memory" "clock" ];

        "sway/workspaces" = {
          #format = "{icon}";
          #format-icons.urgent = "";
        };

        "sway/window".max-length = 64;
        temperature = {
          critical-threshold = 80;
          format = "{icon} {temperatureC} °C";
          format-icons = [ "" "" "" ];
        };

        cpu.format = " {} %";
        memory.format = " {} %";
        battery = {
          format = "{icon} {capacity} %";
          format-icons = [ "" "" "" "" "" ];
        };

        network.format = " {essid} ({signalStrength} %)";

        pulseaudio = {
          format = "{icon} {volume} %";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
        };

        backlight = {
          format = "{icon} {percent} %";
          format-icons = [ "" "" ];
        };

        clock = {
          format = " {:%H:%M %Z}";
          format-alt = " {:%Y-%m-%d}";
        };
      };
    };
  };

  programs.yt-dlp.enable = true;

  services.gammastep = lib.optionalAttrs (osConfig ? location) (
  let inherit (osConfig) location; in {
    inherit (location) provider;
    enable = true;
    settings = {
      general.adjustment-method = "wayland";
    };
  } // lib.optionalAttrs (location.provider == "manual") {
    inherit (location) latitude longitude;
  });

  services.mako = {
    enable = true;
    defaultTimeout = 5000;
  };

  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-iris
      mopidy-local
      mopidy-mpd
      mopidy-mpris
    ];
    settings = {
      core = {
        cache_dir = "$XDG_CACHE_DIR/mopidy";
        config_dir = "$XDG_CONFIG_DIR/mopidy";
        data_dir = "$XDG_DATA_DIR/mopidy";
      };

      audio.mixer = "none";
      file.media_dirs = [ "$XDG_MUSIC_DIR" ];
      local.media_dir = "$XDG_MUSIC_DIR";

      mpd.hostname = "localhost";

      http = {
        hostname = "localhost";
        port = 6680;
        default_app = "iris";
      };
    };
  };

  services.pasystray.enable = true;

  services.swayidle = {
    enable = true;
    events = with cmd; [
      { event = "lock"; command = "${swaylock} -f"; }
      { event = "before-sleep"; command = "${loginctl} lock-session"; }
    ];

    timeouts = with cmd; [
      {
        timeout = 210;
        command = "${brightnessctl} --save -e set 20%-";
        resumeCommand = "${brightnessctl} --restore";
      }
      {
        timeout = 240;
        command = "${loginctl} lock-session";
      }
      {
        timeout = 270;
        command = "${swaymsg} output '* dpms off'";
        resumeCommand = "${swaymsg} output '* dpms on'";
      }
    ];
  };

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  services.udiskie = {
    enable = true;
    automount = false;
  };

  stylix = {
    enable = true;

    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

    fonts = {
      sansSerif = {
        package = pkgs.lato;
        name = "Lato";
      };

      monospace = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };

      sizes.terminal = 11;
    };
  };

  systemd.user.services = lib.genAttrs [ "syncthing" ] (service: {
    Unit = {
      ConditionACPower = true;
      StopPropagatedFrom = [ "power-external.target" ];
    };
  });

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    xwayland = false;

    extraSessionCommands = ''
      export WLR_RENDERER=vulkan

      #for dev in /sys/class/drm/renderD*; do
      #  if [ "$(<"$dev/device/vendor")" == 0x10de ]; then
      #    export WLR_NO_HARDWARE_CURSORS=1
      #    break
      #  fi
      #done
    '';

    config = with cmd; {
      input."*" = {
        xkb_layout = "us,${config.home.keyboard.layout}";
        xkb_options = lib.concatStringsSep ","
          config.home.keyboard.options;
        xkb_switch_layout = "1";
      };

      output = {
        "*" = {
          scale = "1";
          background = "${./wallpaper.png} fill";
          adaptive_sync = "on";
        };

        "Lenovo Group Limited P40w-20 V9084N0R" = {
          resolution = "5120x2160";
          position = "0 0";
          subpixel = "rgb";
        };

        "LG Display 0x06AA Unknown" = {
          position = "0 2160";
          subpixel = "rgb";
        };
      };

      gaps = {
        inner = 4;
        outer = 8;
      };

      bindkeysToCode = true;
      modifier = "Mod4";
      terminal = kitty;

      keybindings = lib.mkOptionDefault {
        XF86MonBrightnessUp = "exec ${brightnessctl} -e set +5%";
        XF86MonBrightnessDown = "exec ${brightnessctl} -e set 5%-";
      };
    };
  };
}
