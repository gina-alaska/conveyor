Conveyor
========

Start of a thought on some code to handle moving data around when it shows up on various systems

Installation
------------

Using rubygems

    gem install gina-conveyor

From source

    git clone https://github.com/gina-alaska/conveyor.git
    cd conveyor
    rake install
 
Usage
-----

Just run the executable to start the conveyor process.  Currently since no daemon mode is available it's best to start conveyor in a screen/tmux session

    $ screen conveyor
    [2012-05-24 13:39:52 -0800] Starting Conveyor v0.0.2
    [2012-05-24 13:39:52 -0800] Loading workers from /home/wfisher/.workers
    [2012-05-24 13:39:52 -0800] Waiting for files
    [2012-05-24 13:39:52 -0800] Press CTRL-C to stop
    [2012-05-24 13:39:52 -0800] Starting websocket on 0.0.0.0:9876

Todo
----

1. Add daemon mode
2. Document worker syntax
3. Finish email notifications
4. Add additional cli options

License
-------

See LICENSE file for licensing and credits.  Think BSD/MIT.
