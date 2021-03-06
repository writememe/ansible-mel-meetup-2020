# Ansible x NAPALM - Multi Vendor Network Lifecycle Management #

This repository contains the code for the accompanying presentation at
 the Melbourne Ansible User Group meetup.
 
 
## Pre-requisites
 
 The following pre-requisites are required in order to use this project:
 
 - Git
 - Python 3.7.x
 
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

## Demo Environment 

Below is the demo environment used for this project:

![Demo Environment](https://github.com/writememe/ansible-mel-meetup-2020/blob/master/diagrams/Ansible%20Demo%20Network%20-%20Diagram%20-%20v1.1.png)
## Project Structure

The overall structure and dependencies of the project is shown in the diagram below:

![Project Structure](https://github.com/writememe/ansible-mel-meetup-2020/blob/master/diagrams/Network%20Automation%20Lifecycle%20Overview%20-%20v1.0.png)

This diagram is a good reference when inspecting playbooks and templates.

Starting from the top-left, the description of the appropriate components are described below.  

### fabric-model.yml - Original Data Model

This YAML file contains the customer/operator data model. All intent should be populated into this file, following the example in the repository. From this file, all subsequent tasks are completed.

As this is a demo, I've used a YAML file as my 'source of truth' as it's portable and highly predicable. Most robust sources of truth
should be used in production.


### create-data-model.yml - Data Model Transformation Playbook

This playbook is used to translate the data model file `fabric-model.yml` into a format which is easier to deploy device configurations from. A focus was made on minimising as much duplicate information as possible when asking the operator to populate this file.  

The destination of this file is in `datamodel/node-model.yml`. This file is overwritten each time it's run, but for your convenience I've uploaded a sample to this repository.  

The playbook uses a Jinja2 template to appropriately take the initial values and render a host friendly data model. I've used the node ID value, plus some Jinja2 techniques to dynamically allocate BGP ASNs and Loopback IP addressing.  

For example, if a node ID is 10, the Jinja2 template will perform the following:  
`bgp_base_asn: 65000` + `node_id: 10` = `node_asn 65010`  

Similarly, if the same node ID of 10 is used, the Jinja2 template will perform the following:  

`loopback_subnet: '192.168.40.0/24'` + `id: 10` = `loopback_ip: 192.168.40.10/32`   

This allows you to simply change the subnet and Base BGP ASN if you would like to deploy the same network at another site or environment by simply changing the `bgp_base_asn` and `loopback_subnet` values.  

Finally, I have implemented interface description default to be `To <remote_hostname> - <remote_interface>` so that unless there is a legitimate exception, this standard can be applied by default without asking the operator to provide this value.

#### Abstraction vs Data Input Decisions

I made the decision to not dynamically populate the routing peer AS numbers so this allows the operator to interconnect to other routing protocols outside the full data model.  

I also decided to not ask the operator to populate the loopback interface number or the name. This is handled statically inside the Jinja2 template. Each vendor names their loopback interfaces differently. The loopback utilised the equivalent of "0"
across the relevant platforms.

### roles/datamodel/templates/per-node.j2 - Data Model Transformation Jinja2 Template

This Jinja2 template is called from the `create-data-model.yml` playbook and performs the transformation of the `fabric-model.yml` to the `datamodel\node-model.yml`. 

### datamodel/node-model.yml - Node-friendly Data Model

This YAML file contains the node-friendly data model. As shown in the picture above, this data model is used by three playbooks to perform various functions. 

### data-model-compare.yml - Data Model Comparison / Planning

This playbook performs a few operations.

Firstly, it generates configurations from the data model file `datamodel/node-model.yml` 
and leverages some vendor specific information in the `group_vars/` directory using Ansible roles 
and Jinja2 templates and output them to the `configs/compiled/<inventory_hostname>` folder.  

There are four roles at used in this playbook:

#### Roles

`base`- This role uses the data model and the applicable `{{os}}` Jinja2 template to create a file (`00-base.conf`) containing the hostname, domain-name and timezone across all operating systems.  

`common`- This role uses the data model and the applicable `{{os}}` Jinja2 template to create a file (`05-common.conf`) containing the NTP server(s), DNS server(s) and syslog servers across all operating systems.  

`interfaces`- This role uses the data model and the applicable `{{os}}` Jinja2 template to create a file (`10-interfaces.conf`) containing the interfaces across all operating systems. Some basic standards have been enforced in the data model, namely the interface description.  

`routing` - This role uses the data model and the applicable `{{os}}` Jinja2 template to create a file (`15-routing.conf`) containing the routing across all operating systems. BGP has been elected as the routing protocol of choice, however the structure and naming convention would allow one to elect any other routing protocol.  

Each BGP instance is configured with the following standards:
- Loopback0 is the router-id for each device as the example 'customer route', which is subsequently advertised throughout the BGP fabric by using a route-map or export-map  
- Every BGP neighbor session has a password set. In my example, it's 'lab' and it's across all neighbours  
- Every BGP neighbor must contain a description      

The playbook then assembles all the four files generated above into one large file (`assembled.conf`), which is used for the final play of the playbook.

The final play connects to each device and compares the file `assembled.conf` with the configuration on the device and reports the differences into a file called `config-diff`.  

The _napalm_install_config_ module is used to perform this comparision. 

### data-model-deploy.yml - Data Model Deployment

This playbook will take the output of the second playbook file `configs/compiled/<hostname>/config-diff`, use this as the config file and install it onto the applicable device.  

For the sake of auditing purposes, all differences are reported to a file named `configs/deployed/<hostname>-deployed-config-diff`

NOTE: Inside the `napalm_install_config` section of this playbook, the `replace_config` value is set to false. 
This results in merging the configuration and is comparatively safer than replacing the config.
Ultimately, one should attempt to achieve replace the entire configuration each time, reaching complete compliance to the automation platform.


### data-model-validate.yml - Validation and Compliance Reporting Playbook

At a high level, this playbook performs three main roles:  

1/ Read the `datamodel/node-model.yml` node friendly data model and generate individual validation files.  
2/ Read the individual validation files created in Step 1 and use the `napalm_validate` module against these validation files.  
3/ Report compliance or non-compliance in three forms; a debug file, an individual compliance report and a collated summary report. 

### roles/validate/templates/per-node-validate.j2 - Validate File Generate Jinja2 Template

This Jinja2 template is called from the `data-model-validate.yml` playbook and performs the transformation of the  `datamodel\node-model.yml` into individual host validation files.

For example, a host named `acme` would have a validation file generated in the location `validate/files/acme/automated-validation.yml`.

### validate/files/{{inventory_hostname}}/automated-validation.yml - Indvidual Host Validation File

The following validation checks are generated from the Jinja2 template:  

#### get_facts

- Check hostname
- Check FQDN

#### get_interfaces

- Check interface is up
- Check interface is enabled
- Check interface description

#### get_interfaces_ip

- Check IP address is correct
- Check prefix length is correct

#### get_bgp_neighbors

- Check BGP peer is present
- Check BGP peer is up
- Check BGP peer is enabled
- Check BGP peer local AS
- Check BGP peer remote AS
- Check BGP peer description
- Check BGP router-id

#### get_lldp_neighbors_detail

- Check remote system hostname

### reports/All-Host-Validation-Report.txt

This file contains a collation of all host compliance reports in a single report. This report is intentionally high-level and quite binary. The reasoning is that generally everything should pass compliance so there is no point hindering the operator with lines and lines of superfluous information.

Each host either has passed or failed all it's compliance checks.

Then, additional high-level information indicates which aspect of the validation had failed. For a detailed analysis, refer to the `reports/debug/`directory for the exact reason for non-compliance.

## CI Pipeline ##

This repository has a CI pipeline using [Travis CI](https://travis-ci.org/). 
This CI pipeline will focus on ensuring all future changes to the project are automatically built and tested, when a pull request is created.

The pipeline has two stages which are described in order below:

### Stage One - yamllint ###

This first stage uses [yamllint](https://github.com/adrienverge/yamllint) to check for syntax validity, key repetition, line length, trailing spaces and indentation of the playbooks, being YAML files.

The command which is executed is:  
`yamllint *.yml`

**NOTE: Line lengths have been modified from level of error to warning in this repository when they are over 80 characters in length.
For more information, please refer to the [yamllint configuration file](https://github.com/writememe/ansible-mel-meetup-2020/blob/master/.yamllint.yaml)**

### Stage Two - ansible-lint ###

The command which is executed is:  
`ansible-lint *.yml`

### Summary

Whilst the pipeline is purely used for linting, it's a good idea to get into the practice of ensuring everyone's contribution
meets some minimum standards before issuing pull requests.

## Makefile

The Makefile provides the following options:

```makefile
  clean-dir                 Remove all automatically generated directories caused from playbooks.
  deploy                    Deploy the applicable changes to the fabric, based on the design.
  design                    Design the applicable changes to the fabric.
  linting-checks            Perform ansible-lint and yamllint on all files.
  network-lifecycle         Plan, design, deploy and validate data model (all playbooks).
  plan                      Create node-friendly data model from your fabric plan.
  validate                  Validate the fabric solution.
```

Follow the examples in the file to make more.

Shoutout to Rick Donato for the [reference example](https://github.com/rickdonato/repo-template/blob/master/Makefile)