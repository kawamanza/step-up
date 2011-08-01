# StepUp: a project to step up your projects

StepUp is a tool to manage versioning.
That means you can bump the version of your project, for example, from v3.0.11 to v4.0.0, check the current version, summarize all the history of versions in a changelog and more.

StepUp is based on source control management features (i.e. tags, branches, commits, notes etc), so it doesn't need to keep files with the current version (but it supports it, if you want), it has visibility of all history of changes and versions (doesn't matter if they are spread in many different branches), which adds a variety of possibilities in terms of management, depending on your project needs.

## Installation

    gem install step-up

## First of all

Your installed git-scm version must be v1.7.1 or higher.

## The Basics

### Checking current project version

    stepup [version]

An example of output would be

    v0.2.0+3

Consider that your project has a tag named "v0.2.0".
The "+3" part of the output above means the project has three commits since last version tag.
The format of the version is totally customizable, and we will cover in more detail later.

### Stepping up a version

    stepup version create [--level LEVEL_NAME] [--no-editor]

where **LEVEL_NAME**, by default, could be  

* major
* minor
* patch
* tiny

This command will ask user to input a message for the version and will increment the version number accordingly.

Each level corresponds to a position in the version mask.
Considering default settings, this means:

    v0.0.0.9 => vMAJOR.MINOR.PATCH.TINY

The versioning increment is based on the last version tag found in the repository, and works as follows:

    v0.5.3.2 => v0.5.3.3 (TINY increment)
    v0.5.3.2 => v0.5.4   (PATCH increment)
    v0.5.3.2 => v0.6.0   (MINOR increment)
    v0.5.3.2 => v1.0.0   (MAJOR increment)

As you can see, the TINY level is omitted when its value is zero.
The mask allows you to configure the less relevant levels this way.

### Checking out the changelog

    stepup changelog [--top=N]

## StepUp beyond basics

### Working with notes

With StepUp we are able to attach additional comments on existing commit objects.
*The great goal of this Gem is giving to developers an easy way to manage these notes*.

The note was created with the following command:

    $ stepup notes add --section bugfixes -m "support for old installations"

Still with this example we can check the created note with the following command:

    $ stepup notes
    ---
    Bugfixes:

      - support for old installations

The command above fetches the entire commit history, gets each note and organizes them in sections.
Found notes are displayed as a big changelog message.

### Creating rich changelogs

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
