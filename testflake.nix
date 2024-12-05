{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    ollama.url = "github:abysssol/ollama-flake";
    #ollama.inputs.nixpkgs.follows = "nixpkgs"; # this could break the build unless using unstable nixpkgs
  };

  outputs = { nixpkgs, ollama, ... }:
    let
      system = abort "system needs to be set";
      # to access the rocm package of the ollama flake:
      ollama-rocm = ollama.packages.${system}.rocm;
      #ollama-rocm = inputs'.ollama.packages.rocm; # with flake-parts

      pkgs = nixpkgs.legacyPackages.${system};
      # you can override package inputs like with nixpkgs
      ollama-cuda = ollama.packages.${system}.cuda.override { cudaGcc = pkgs.gcc11; };
    in
    {
      # output attributes go here
    };
};
