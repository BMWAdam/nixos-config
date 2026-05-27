{ config, pkgs, ... }:
{
    services.fprintd.enable = true;
    security.pam.services.login.fprintAuth = true;
    security.pam.services.sudo.fprintAuth = true;
}