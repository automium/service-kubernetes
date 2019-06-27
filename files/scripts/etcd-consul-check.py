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

    exitcode = 2
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
        context.load_verify_locations(args.ca)
        context.load_cert_chain(args.crt, args.key)

        conn = http.client.HTTPSConnection(args.host, context=context)
        conn.putrequest('GET', '/health')
        conn.endheaders()
        response = conn.getresponse().read()
        responseObject = json.loads(response)
        if json.loads(responseObject["health"]):
            message = f'Node health status={responseObject["health"]}'
            exitcode = 0
        else:
            message = f'Node health status={responseObject["health"]}'
            exitcode = 2
    except:
        message = f"check fail check Traceback"
        exitcode = 2
    gtfo(exitcode=exitcode, message=message)


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
    parser.add_option('-c', '--ca', help='certification autority path',
                      default="/etc/ssl/etcd/ssl/ca.pem", type=str,
                      dest='ca', metavar='/path/ca.pem')
    parser.add_option('-r', '--cert-file', help='certificate file path',
                      default="/etc/ssl/etcd/ssl/cer.pem",
                      type=str, dest='crt', metavar='/path/cert.pem')

    parser.add_option('-k', '--key', help='certificate key path',
                      default="/etc/ssl/etcd/ssl/key.pem",
                      type=str, dest='key', metavar='/path/key.pem')

    parser.add_option('-e', '--etcd-host', help='etcd host and ports',
                      default="127.0.0.1:2379", type=str,
                      dest='host', metavar='127.0.0.1:2379')

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
