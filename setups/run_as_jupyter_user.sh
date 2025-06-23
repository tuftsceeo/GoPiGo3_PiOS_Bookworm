# Set up JupyterLab configuration
echo "ENTER SOME JUPYTER PASSWORDS PLEASE"
sleep 10
cd /home/jupyter
jupyter lab --generate-config 
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/jupyter_lab_config.py /home/jupyter/.jupyter/jupyter_lab_config.py
echo "ENTER REGULAR EDL PASSWORD"
jupyter lab password


# Copy the Jupyter service file to systemd
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/jupyter.service /etc/systemd/system/jupyter.service
sudo systemctl daemon-reload
sudo systemctl enable jupyter.service 
sudo systemctl start jupyter.service 

# Install Shell In A Box
sudo apt install shellinabox
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/shellinabox_config /etc/default/shellinabox

cd /home/jupyter
sudo cp /home/pi/Dexter/GoPiGo3/Software/Python/Examples /home/jupyter/Examples
sudo chgrp -R users /home 
sudo chmod -R g+rwx /home

echo "REMINDER - You need to clone in the EDL jupyter notebooks"
cd /home/jupyter
echo "git clone https://your-username:your-token@github.com/tuftsceeo/EDL.git"
sleep 30
echo "JUPYTER LAB READY"