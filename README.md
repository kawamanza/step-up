# StepUp: a project to 'step up' your projects
StepUp is a tool to manage versioning based on source control management features (i.e. tags and notes of Git). That is, you don't need to keep track of your application version in a file anymore !!!

## Prerequisite
This is temporary but for now StepUp just works with Git version 1.7.1 and above.

## Installation
    gem install step-up

## First of all
Have in mind that StepUp has only Git support for now (more to come soon!!), so any StepUp command must be performed inside a git repository path.
With that said, run

    stepup init
This will prepare your repository to use one of the coolest feature of StepUp called ***notes***
Besides that it will create a file in your project called **.stepuprc** 
We'll cover more about this in the next sections.

## The Basics
### Check out the version
    stepup version
This will tell you the application version based on Git tag.
Currently the result of this command on StepUp project itself will be

    v0.2.0+1
The "+1" part means the project has one commit since last version.
The format of the version is totally customizable through **.stepuprc** which we will cover in the next sections.

### Create new version
    stepup version create --level LEVEL_NAME
where **LEVEL_NAME** can be 

* major
* minor
* tiny
* patch
* rc

This command will ask user for a message for the version and will increment the version number accordingly

### Check out the history
    stepup changelog --top N
where **N** is the number of versions that will be displayed from newer to older ones

## StepUp beyond basics
***Comming soon***

## Report bugs and suggestions

  * [Issue Tracker](https://github.com/kawamanza/step-up/issues)

## Authors

 * [Eric Fer](https://github.com/ericfer)
 * [Marcelo Manzan](https://github.com/kawamanza)