# n8n.nix
{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      n8n = {
        image = "n8nio/n8n";
        ports = [ "5678:5678" ];
        environment = { N8N_SECURE_COOKIE = "false"; };
        extraOptions = [
          "--rm" # Remove container when it exits
        ];
      };
    };
  };

  # Optional: Open firewall port
  networking.firewall.allowedTCPPorts = [ 5678 ];
}
