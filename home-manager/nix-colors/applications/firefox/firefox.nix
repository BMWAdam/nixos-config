{ pkgs, inputs, lib, config, firefox-addons, ... }:

let
  colors = config.colorScheme.palette;
in {
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";

      settings = {
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
        "ui.systemUsesDarkTheme" = 1;
        "layout.css.prefers-color-scheme.content-override" = 2;

        # Disable sponsored shortcuts on new tab
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # Disable sponsored suggestions in URL bar
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.quicksuggest.enabled" = false;

        # Disable Pocket (also removes Pocket-sponsored content)
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

        # Disable Firefox “shopping” sidebar
        "browser.shopping.experience2023.enabled" = false;

        # Disable Firefox Account & Sync
        "identity.fxaccounts.enabled" = false;
        "identity.fxaccounts.toolbar.enabled" = false;

        # Disable Firefox View (requires account)
        "browser.tabs.firefox-view" = false;

        # Disable Mozilla VPN ads
        "browser.privatebrowsing.vpnpromourl" = "";

        # Disable Normandy (remote experiments)
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";

        # Disable telemetry & data reporting
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.archive.enabled" = false;

        # Disable studies
        "app.shield.optoutstudies.enabled" = false;

        # Disable crash reports
        "browser.tabs.crashReporting.sendReport" = false;
        "breakpad.reportURL" = "";

        "alerts.useSystemBackend" = true;
      };

      userChrome = ''
        :root {
          --base00: #${colors.base00};
          --base01: #${colors.base01};
          --base02: #${colors.base02};
          --base03: #${colors.base03};
          --base04: #${colors.base04};
          --base05: #${colors.base05};
          --base06: #${colors.base06};
          --base07: #${colors.base07};
          --base08: #${colors.base08};
          --base09: #${colors.base09};
          --base0A: #${colors.base0A};
          --base0B: #${colors.base0B};
          --base0C: #${colors.base0C};
          --base0D: #${colors.base0D};
          --base0E: #${colors.base0E};
          --base0F: #${colors.base0F};
        }

        /* Toolbar */
        #TabsToolbar {
          background: var(--base00) !important;
        }

        /* Tabs */
        .tabbrowser-tab {
          border-radius: 6px !important;
          margin: 2px !important;
        }

        .tabbrowser-tab[selected="true"] {
          background: var(--base02) !important;
          color: var(--base06) !important;
        }

        /* URL bar */
        #urlbar {
          background: var(--base01) !important;
          border-radius: 6px !important;
        }
      '';

      userContent = ''
        :root {
          --base00: #${colors.base00};
          --base05: #${colors.base05};
        }

        @-moz-document url-prefix("about:") {
          body {
            background: var(--base00) !important;
            color: var(--base05) !important;
          }
        }

        /* Remove the leftmost Firefox menu button */
        #PanelUI-button {
          display: none !important;
        }
      '';

      extensions =  {
        packages = with firefox-addons.packages.${pkgs.system}; [
          darkreader
          ublock-origin
        ];
        force = true;
      };
    };
  };
}
