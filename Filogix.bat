:: !/bin/bash
@echo off
TITLE FSC Scratch Org
ECHO this batch file will setup the FSC scratch org. Press any key to continue
PAUSE
set /p alias="Enter ScratchOrg Alias (Example: ABCScratch): "

:: create scratch org for 30 days with specific conf
start /wait sfdx force:org:create -f config/project-scratch-def.json -a %alias% --setdefaultusername -d 30

:: pckg installations
:: FSC
start /wait sfdx force:package:install --package 04t1E000000jb9R -w 20 
:: FSC Extn
:: Has all fieldsets for Lightning pages like Financial Account tab on Account
start /wait sfdx force:package:install --package 04t1E000001Iql5 -w 20
:: FSC Extn Commercial Banking* 
:: Requires more dashboards
:: sfdx force:package:install --package 04t80000000lTrZ -w 20
:: FSC Extn Retail Banking
:: sfdx force:package:install --package 04t80000000lTp4 -w 20
:: FSC Einstein Bots
:: sfdx force:package:install --package 04t80000000lTqH -w 20
:: FSC Lightning Flow Templates
start /wait sfdx force:package:install --package 04t3i000000jP1g -w 20

:: Pushing the Source
start /wait sfdx force:source:push -f

start /wait sfdx force:user:permset:assign -n FinancialServicesCloudStandard
start /wait sfdx force:user:permset:assign -n Mortgage
start /wait sfdx force:user:permset:assign -n DocumentChecklist
:: This permission set is for data load as some permissions are not assigned yet
start /wait sfdx force:user:permset:assign -n Mortgage_Junction

:: Generate user password
start /wait sfdx force:user:password:generate -u %alias%
:: Opening the org in browser
start /wait sfdx force:org:open