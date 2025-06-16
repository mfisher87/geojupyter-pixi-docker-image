# GeoJupyter docker image (pixi)

Pixi is **much** faster than Conda.
For this set of dependencies, we experience a 10x+ speedup in solving.
This repo explores building a JupyterHub-compatible Docker image using Pixi.


## Usage

Use the image:

```bash
ghcr.io/mfisher87/geojupyter-pixi:${VERSION}
```

It's best to specify a specific hash or tag for `${VERSION}` to ensure you get what you
want.
If you just need to try it out real quick, you can use `latest`, but it's generally not
recommended.
