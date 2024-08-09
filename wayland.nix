{ config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  cmd = {
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    fish = "${osConfig.programs.fish.package}/bin/fish";
    grim = "${pkgs.grim}/bin/grim";
    hyprctl = "${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl";
    hyprlock = "${config.programs.hyprlock.package}/bin/hyprlock";
    jq = "${config.programs.jq.package}/bin/jq";
    keepassxc = "${pkgs.keepassxc}/bin/keepassxc";
    kitty = ''${config.programs.kitty.package}/bin/kitty --single-instance --instance-group "$XDG_SESSION_ID"'';
    loginctl = "${osConfig.systemd.package}/bin/loginctl";
    mpv = "${config.programs.mpv.package}/bin/mpv";
    pidof = "${pkgs.procps}/bin/pidof";
    playerctl = "${pkgs.playerctl}/bin/playerctl";
    slurp = "${pkgs.slurp}/bin/slurp";
    tofi-run = "${config.programs.tofi.package}/bin/tofi-run";
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    wpctl = "${osConfig.services.pipewire.wireplumber.package}/bin/wpctl";
    xdg-open = "${pkgs.xdg-utils}/bin/xdg-open";
  };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
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
    #inkscape
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

  home.keyboard = {
    layout = "greedy";
    options = "ctrl:nocaps";
  };

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
        csquotes
        hyperref
        paralist
        realscripts
        unicode-math
        units
        xecjk
        xecolor
        xltxtra
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
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "tray" "network" "pulseaudio" "backlight" "battery" "temperature" "cpu" "memory" "clock" ];

        "hyprland/workspaces" = {
          #format = "{icon}";
          #format-icons.urgent = "";
        };

        "hyprland/window".max-length = 64;
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

  services.hypridle = {
    enable = true;
    settings = {
      general = with cmd; {
        lock_cmd = "${pidof} hyprlock || ${hyprlock}";
        before_sleep_cmd = "${loginctl} lock-session";
        after_sleep_cmd = "${hyprctl} dispatch dpms on";
      };

      listener = with cmd; [
        {
          timeout = 210;
          on-timeout = "${brightnessctl} --save -e set 20%-";
          on-resume = "${brightnessctl} --save -e set +20%";
        } {
          timeout = 240;
          on-timeout = "${loginctl} lock-session";
        } {
          timeout = 270;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }
      ];
    };
  };

  services.hyprpaper =
  let
      wallpaper = toString ./wallpaper.png;
  in {
    enable = true;
    settings = {
      ipc = false;
      preload = [ wallpaper ];
      wallpaper = [ wallpaper ];
    };
  };

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

    targets = {
      hyprpaper.enable = lib.mkForce false;
    };
  };

  systemd.user.targets.tray = {
    Unit = {
      BindsTo = "waybar.service";
      After = "waybar.service";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = [
        #"desc:LG Display 0x06AA, 1440x900, 0x0, 1, bitdepth, 10"
        "desc:LG Display 0x06AA, highres, 0x2160, 1, bitdepth, 10"
        "desc:Lenovo Group Limited P40w-20 V9084N0R, highres, 0x0, 1, bitdepth, 10"
      ];

      input = {
        kb_layout = "greedy";
        kb_options = "ctrl:nocaps";
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;

        layout = "dwindle";
      };

      gestures.workspace_swipe = true;

      misc = {
        disable_hyprland_logo = true;
        vrr = 1;
        no_direct_scanout = false;
        background_color = lib.mkForce "0x181825";
      };

      decoration = {
        rounding = 8;
      };

      dwindle.preserve_split = true;

      workspace = [
        "name:0, monitor:desc:LG Display 0x06AA, default:true"
        "name:A, monitor:desc:LG Display 0x06AA"
      ];

      "$mod" = "SUPER";

      bind = with cmd; [
        # exit
        "$mod SHIFT, code:28, exit"

        # window state
        "$mod SHIFT, Space, togglefloating"
        "$mod, code:32, fullscreen"
        "$mod, code:48, togglesplit"
        "$mod SHIFT, code:24, killactive"

        # change focus
        "$mod, left,    movefocus, l"
        "$mod, code:43, movefocus, l"
        "$mod, right,   movefocus, r"
        "$mod, code:46, movefocus, r"
        "$mod, up,      movefocus, u"
        "$mod, code:45, movefocus, u"
        "$mod, down,    movefocus, d"
        "$mod, code:44, movefocus, d"

        # move window
        "$mod SHIFT, left,    movewindow, l"
        "$mod SHIFT, code:43, movewindow, l"
        "$mod SHIFT, right,   movewindow, r"
        "$mod SHIFT, code:46, movewindow, r"
        "$mod SHIFT, up,      movewindow, u"
        "$mod SHIFT, code:45, movewindow, u"
        "$mod SHIFT, down,    movewindow, d"
        "$mod SHIFT, code:44, movewindow, d"

        # resize window
        "$mod CTRL, left,    resizeactive, -20 0"
        "$mod CTRL, code:43, resizeactive, -20 0"
        "$mod CTRL, right,   resizeactive, 20 0"
        "$mod CTRL, code:46, resizeactive, 20 0"
        "$mod CTRL, up,      resizeactive, 0 -20"
        "$mod CTRL, code:45, resizeactive, 0 -20"
        "$mod CTRL, down,    resizeactive, 0 20"
        "$mod CTRL, code:44, resizeactive, 0 20"

        # move floating
        "$mod ALT, left,    moveactive, -20 0"
        "$mod ALT, code:43, moveactive, -20 0"
        "$mod ALT, right,   moveactive, 20 0"
        "$mod ALT, code:46, moveactive, 20 0"
        "$mod ALT, up,      moveactive, 0 -20"
        "$mod ALT, code:45, moveactive, 0 -20"
        "$mod ALT, down,    moveactive, 0 20"
        "$mod ALT, code:44, moveactive, 0 20"

        # switch workspaces
        "$mod, code:49, workspace, name:0"
        "$mod, code:10, workspace, name:1"
        "$mod, code:11, workspace, name:2"
        "$mod, code:12, workspace, name:3"
        "$mod, code:13, workspace, name:4"
        "$mod, code:14, workspace, name:5"
        "$mod, code:15, workspace, name:6"
        "$mod, code:16, workspace, name:7"
        "$mod, code:17, workspace, name:8"
        "$mod, code:18, workspace, name:9"
        "$mod, code:19, workspace, name:A"
        "$mod, code:20, togglespecialworkspace"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # send to workspaces
        "$mod SHIFT, code:49, movetoworkspacesilent, name:0"
        "$mod SHIFT, code:10, movetoworkspacesilent, name:1"
        "$mod SHIFT, code:11, movetoworkspacesilent, name:2"
        "$mod SHIFT, code:12, movetoworkspacesilent, name:3"
        "$mod SHIFT, code:13, movetoworkspacesilent, name:4"
        "$mod SHIFT, code:14, movetoworkspacesilent, name:5"
        "$mod SHIFT, code:15, movetoworkspacesilent, name:6"
        "$mod SHIFT, code:16, movetoworkspacesilent, name:7"
        "$mod SHIFT, code:17, movetoworkspacesilent, name:8"
        "$mod SHIFT, code:18, movetoworkspacesilent, name:9"
        "$mod SHIFT, code:19, movetoworkspacesilent, name:A"
        "$mod SHIFT, code:20, movetoworkspacesilent, special"

        # function keys
        ", XF86MonBrightnessUp,   exec, ${brightnessctl} -e set +5%"
        ", XF86MonBrightnessDown, exec, ${brightnessctl} -e set 5%-"
        ", XF86AudioRaiseVolume,  exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ +2dB"
        ", XF86AudioLowerVolume,  exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ -2dB"
        ", XF86AudioMute,         exec, ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute,      exec, ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioNext,         exec, ${playerctl} next"
        ", XF86AudioPrev,         exec, ${playerctl} previous"
        ", XF86AudioPlay,         exec, ${playerctl} play"
        ", XF86AudioStop,         exec, ${playerctl} pause"
        ", XF86Explorer,          exec, ${xdg-open} https:"

        # screenshots
        "$mod, Print,             exec, ${grim} -l 9 - | ${wl-copy}"
        "$mod SHIFT, Print,       exec, ${slurp} | ${grim} -g - -l 9 - | ${wl-copy}"
        ''$mod CTRL, Print,        exec, ${grim} -g "$(${hyprctl} -j activewindow ${jq} -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" -l 9 - | ${wl-copy}''
        "$mod, Return,  exec, ${kitty}"
        "$mod Shift, Return,  exec, ${kitty} ${fish} --private"
        "$mod, code:55, exec, $(${tofi-run})"
        "$mod, code:56, exec, ${loginctl} lock-session"
      ];

      bindm = [
        # move window
        "$mod, mouse:272, movewindow"

        # resize window
        "$mod, mouse:273, resizewindow"
      ];

      "$keepassPopup" = ''class:^org\.keepassxc\.KeePassXC$, title:^(Unlock.*|.*Access Request)$'';

      windowrulev2 = [
        ''workspace name:A silent, class:^org\.keepassxc\.KeePassXC$, title:^Vault\.kdbx''
        "float, $keepassPopup"
        "center, $keepassPopup"
        "dimaround, $keepassPopup"
        "stayfocused, $keepassPopup"
      ];

      exec-once = with cmd; [
        "${keepassxc}"
      ];

      env = [
        "__GL_GSYNC_ALLOWED, 1"
        "__GL_SYNC_TO_VBLANK, 1"
        "__GL_VRR_ALLOWED, 1"
        "CLUTTER_BACKEND, wayland"
        "GDK_BACKEND, wayland,x11"
        "QT_QPA_PLATFORM, wayland;xcb"
        #"SDL_VIDEODRIVER, wayland"
        "WLR_NO_HARDWARE_CURSORS, 1"
      ];

      animations = {
        bezier = [
          "wind, 0.2, 0.9, 0.2, 1.05"
          "winMov, 0.2, 0.9, 0.2, 1.08"
          "winIn, 0.2, 0.9, 0.2, 1.08"
          "winOut, 0.2, 0, 0.9, 0.2"
          "liner, 1, 1, 1, 1"
        ];

        animation = [
          "windows, 1, 4, wind, slide"
          "windowsIn, 1, 4, winIn, slide"
          "windowsOut, 1, 4, winOut, slide"
          "windowsMove, 1, 4, winMov, slide"
          "fade, 1, 4, default"
          "fadeOut, 1, 4, default"
          "workspaces, 1, 4, wind"
        ];
      };

      cursor.no_hardware_cursors = true;
    };
  };
}
