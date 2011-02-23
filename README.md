# StepUp: a project to step up your projects
StepUp is a tool to manage versioning based on source control management features (i.e. tags and notes of Git).

## Prerequisite
Git version 1.7.1 and above.

## Installation

    gem install step-up

## First of all
Have in mind that StepUp has only Git support for now (more to come soon!!), so any StepUp command must be performed inside a git repository path.
With that said, run

    stepup init

It will create a file in your project called **.stepuprc** 
We'll cover more about this in the next sections.

## The Basics
### Checking out the current version

    stepup version 

or just

    stepup

This will tell you the current application version. 

One example of output would be

    v0.2.0+1

The "+1" part means the project has one commit since last version.
The format of the version is totally customizable through **.stepuprc** which we will cover in more detail later.

### Creating new version

    stepup version create --level LEVEL_NAME

where **LEVEL_NAME**  

* major
* minor
* patch
* tiny

This command will ask user to input a message for the version and will increment the version number accordingly.

Each level corresponds to a position in tha version mask.
Considering default settings of .stepuprc, this means:

    v0.0.0.0 => vMAJOR.MINOR.PATCH.TINY

### Checking out the changelog

    stepup changelog

## StepUp beyond basics
***Comming soon***

## Project
* https://github.com/kawamanza/step-up

## Report bugs and suggestions
* [Issue Tracker](https://github.com/kawamanza/step-up/issues)

## Authors
 * [Eric Fer](https://github.com/ericfer)
 * [Marcelo Manzan](https://github.com/kawamanza) 
 
## Collaborators
 * [Lucas Fais](https://github.com/lucasfais)