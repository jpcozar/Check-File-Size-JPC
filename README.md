# check_file_size

Nagios Plugin for check the size of a local file - Javier Polo Cózar <jpcozar@yahoo.es>

This script is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

This script will check the file size giving output in B(ytes),K(Bytes),M(egaBytes),G(igaBytes). 
Moreover, it is possible to set a thresold for warning and critical file size.
## Examples
```
check_file_size.sh -f /etc/hosts.allow -w 10 -c 15 -u B

CRITICAL - Filesize: 419 B | Filesize=419B;10;15;
```
```
check_file_size.sh -f /home/staffadm/.duc.db -w 15 -c 20 -u Gb

WARNING - Filesize: 15.88 Gb | Filesize=15.88Gb;15;20;
```

## Nagios' configuration

### commands.cfg
```
define command{
command_name check_file_size
command_line $USER1$/check_file_size.sh -f $ARG1$ -w $ARG2$ -c $ARG3$ -u $ARG4$
}
```
### localhost.cfg
```
define service{
        use                             local-service
        host_name                       server
        service_description             duc server ddbb
        check_command check_file_size!"/home/staffadm/.duc.db"!20!25!Gb
}
```





