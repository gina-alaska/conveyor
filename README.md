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

Worker Commands
---------------

#### `run 'COMMAND', [options]`

Runs the specified command in a shell

**Options**
* quite (boolean) - suppress any output from the command, default: false
* timeout (seconds) - the command stop execution after give number of seconds, default: 600 (10 minutes)

#### `scp 'FILE', 'DESTINATION', [options]`

SCP the specified file to a remote DESTINATION.  DESTINATION uses the same format as the actual `scp` command.

**Options**
* quite (boolean) - suppress any output from the command, default: false
* timeout (seconds) - the command stop execution after give number of seconds, default: 600 (10 minutes)

**WARNING:** You will need to have ssh/scp'd to the host manually once in order to ensure that the host key and ssh keys are available for this command.

#### `copy 'FILE', 'DESTINATION'`

Copy the specified file to DESTINATION.  DESTINATION can be a folder or another filename

### `move 'FILE', 'DESTINATION'`

Move the specified file to DESTINATION.  DESTINATION can be a folder or another filename

#### `delete 'FILE'`

Deletes the specified file

#### `error 'MESSAGE'`, `info 'MESSAGE'`

Print info out to various log files and consoles

License
-------

See LICENSE file for licensing and credits.  Think BSD/MIT.
