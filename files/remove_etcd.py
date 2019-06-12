#! /usr/bin/env python3

###############################################################################
# Consul plugin for check ETCD node
#
# Notes
# - The RHEL boxes I work on are currently limited to Python 2.6.6, hence the
#   use of (deprecated) optparse. If I can ever get them all updated to
#   Python 2.7 (or better yet, 3.3), I'll switch to argparse
# - This template runs in 2.6-3.3. Any changes made will need to be appropriate
#   to the Python distro you want to use
#
###############################################################################

from optparse import OptionParser, OptionGroup
import logging as log
import ssl
import json
import http.client
import pprint
import os

__author__ = 'Attilio Greco'
__version__ = 0.1

def main():

    # Parse command-line arguments
    args, args2 = parse_args()

    # Uncomment to test logging levels against verbosity settings
    # log.debug('debug message')
    # log.info('info message')
    # log.warning('warning message')
    # log.error('error message')
    # log.critical('critical message')
    # log.fatal('fatal message')
    hostname = os.uname()[1]

    etcd_ca = f"/etc/ssl/etcd/ssl/ca.pem"
    etcd_crt = f"/etc/ssl/etcd/ssl/member-{hostname}.pem"
    etcd_key = f"/etc/ssl/etcd/ssl/member-{hostname}-key.pem"

    remove_list = []
    context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    context.load_verify_locations(etcd_ca)
    context.load_cert_chain(etcd_crt, etcd_key)
    conn = http.client.HTTPSConnection(args.etcd_host, context=context)
    conn.putrequest('GET', '/v2/members')
    conn.endheaders()
    response = conn.getresponse().read()
    responseObject = json.loads(response)
    member_list = responseObject


    for member in member_list['members']:
        if (member['name'] == args.cluster_etcd_host and args.cluster_etcd_host != "") or args.cluster_ip_check in str(member['peerURLs']):
            log.debug(f"add {member['name']} to remove list ( Raft-ID: {member['id']} )")
            remove_list.append(member['id'])
        else:
            log.debug(f"not the host im checking, member: {member['name']}, IP {member['peerURLs']} check host: cluster_etcd_host IP: {args.cluster_ip_check}  ")
    
    log.debug(f"{remove_list}")
    if len(remove_list) == 0:
        gtfo(0, f'Status: 0; Status-Verbose: Host not in cluster; Debug: {remove_list}')
    elif len(remove_list) == 1:
        remove_url = f"/v2/members/{remove_list[0]}"
        log.debug(remove_url)
        conn.putrequest('DELETE', remove_url)
        conn.endheaders()
        response = conn.getresponse()
        if 200 < response.status and 300 > response.status:
            log.info(f"Status: {response.status} Reason: {response.reason}")
            gtfo(0, f'Status: 1; Status-Verbose: Host in cluster, stop etcd, delete lib/etcd; Debug: {remove_list}')
        else:
            gtfo(1, f"Status: {response.status} Reason: {response.reason}")
    elif len(remove_list) > 1:
        gtfo(1, f'Remove list have more than 1 element {remove_list}')    
    else:
        gtfo(1, f'Undefined Case RemoveList | {remove_list}')
    




def parse_args():
    """ Parse command-line arguments """

    parser = OptionParser(usage='usage: %prog [-v|vv|vvv] [options]',
                          version='{0}: v.{1}')

    # Verbosity (want this first, so it's right after --help and --version)
    parser.add_option('-v', help='Set verbosity level',
                      action='count', default=0, dest='v')

    # CLI arguments specific to this script
    group = OptionGroup(parser, 'Plugin Options')
    group.add_option('-x', '--extra', help='Your option here',
                     default=None)

    # Common CLI arguments

    parser.add_option('-e', '--etcd-host', help='etcd host and ports',
                      default="127.0.0.1:2379", type=str,
                      dest='etcd_host', metavar='127.0.0.1:2379')
    
    parser.add_option('-s', '--cluster-host-check', help='etcd host and ports',
                      default="", type=str,
                      dest='cluster_etcd_host', metavar='my-etcd')

    parser.add_option('-p', '--cluster-ip-check', help='etcd host and ports',
                      default="999.999.999.999", type=str,
                      dest='cluster_ip_check', metavar='10.2.0.10')

    parser.add_option_group(group)

    try:
        args, args2 = parser.parse_args(testargs.split())
    except NameError:
        args, args2 = parser.parse_args()

    # Set the logging level based on the -v arg
    log.getLogger().setLevel([log.ERROR, log.WARN, log.INFO,
 log.DEBUG][args.v])

    log.debug('Parsed arguments: {0}'.format(args))
    log.debug('Other  arguments: {0}'.format(args2))

    return args, args2


def gtfo(exitcode, message=''):
    """ Exit gracefully with exitcode and (optional) message """

    log.debug('Exiting with status {0}. Message: {1}'.format(
        exitcode, message))

    if message:
        print(message)
    exit(exitcode)


if __name__ == '__main__':
    # Initialize logging before hitting main
    log.basicConfig(
        level=log.DEBUG, format='%(funcName)s - %(levelname)s - %(message)s')
    main()
