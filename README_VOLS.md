# Copy to/from Fly Volumes
- From https://community.fly.io/t/how-to-copy-files-off-a-vm/1651/8

    - fly wireguard create, suffix the profile name with .conf, import into wireguard and connect to it, now you can reach to your kristas-dogs.internal
        - copy to `kristas-dogs-wireguard.conf`
        - DO NOT check this file into Git
    - install / run Wireguard VPN
        - load the .conf file
    - flyctl ssh issue --agent to add the proper ssh key there, otherwise you get permission denied
    - ssh root@kristas-dogs.internal
        - TBD If pushing files onto volume, install openssh-client apt-get install openssh-client, otherwise you get “scp command not in $PATH”.
    
    - to pull: 
        ```
        scp root@kristas-dogs.internal:/mnt/kristas_dogs_db_vol/kristas_dogs_prod.db DB/kristas_dogs_prod.db
        ```
    - TBD to push: scp foo.db root@kristas-dogs.internal:/data/foo.db, for some reason it hangs
        - redeploy the app so it loads the latest file

