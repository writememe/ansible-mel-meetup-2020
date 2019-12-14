# Ansible x NAPALM - Multi Vendor Network Lifecycle Management #

This repository contains the code for the accompanying presentation at
 the Melbourne Ansible User Group meetup.
 
## Pre-requisites
 
 The following pre-requisites are required in order to use this project:
 
 - Git
 - Python 3.6 or greater
 
## Base Installation ##

To install the relevant modules and dependencies, please perform the following:

1) Setup a Python Virtual Environment. Two examples of this are [Pycharm](https://www.jetbrains.com/help/pycharm/creating-virtual-environment.html) 
and [Visual Studio Code](https://code.visualstudio.com/docs/python/environments)
2) Inside the virtual environment, clone the repository and install the `requirements.txt`
```python
git clone https://github.com/writememe/ansible-mel-meetup-2020.git
cd ansible-mel-meetup-2020
pip install -r requirements
```

## Environment-Specific Installation ##

1) Populate the `hosts` file with your environment-specific information. 
Use the example provided in the repository to ensure you have the relevant information.
2) Populate the `fabric-model.yml` data model file. Use the example provided in the repository to ensure you have the relevant information.

## Project Structure

The overall structure and dependencies of the project is shown in the diagram below:

![Project Structure](https://github.com/writememe/ansible-mel-meetup-2020blob/master/diagrams/Network%20Automation%20Lifecycle%20Overview%20-%20v1.0.png)

This diagram is a good reference when inspecting playbooks and templates.

## Demo Environment 

Below the demo environment used for this project:

![Demo Environment](https://github.com/writememe/ansible-mel-meetup-2020blob/master/diagrams/Ansible%20Demo%20Network%20-%20Diagram%20-%20v1.1.png)
