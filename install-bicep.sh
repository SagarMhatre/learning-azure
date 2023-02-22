#Ref: https://stackoverflow.com/a/12276562/2795764
# sudo chmod 755 install-bicep.sh 
# ./install-bicep.sh


# Ref : https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#via-bash
# Fetch the latest Bicep CLI binary
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-osx-x64
# Mark it as executable
chmod +x ./bicep
# Add Gatekeeper exception (requires admin)
sudo spctl --add ./bicep
# Add bicep to your PATH (requires admin)
sudo mv ./bicep /usr/local/bin/bicep
# Verify you can now access the 'bicep' command
bicep --help
# Done!

# bicep --version
# Bicep CLI version 0.14.46 (ef2ceb1a0e)