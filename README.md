# Rejig: A Scalable Online Algorithm for Cache Server Configuration Changes

This repository centralizes an implementation of [this paper](http://dblab.usc.edu/Users/papers/rejig.pdf) using memcached. Each individual module is implemented in its own repository (as a git submodule).

## Build
Each folder inside the project is a git submodule, or it's own project.
You need to build each sub-project using gradle build.

## Running experiments
To run the experiments with the current distribution us `run.sh`.