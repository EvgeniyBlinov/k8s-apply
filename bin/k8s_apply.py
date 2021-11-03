#!/usr/bin/env python

import yaml
import os
from subprocess import call

INFO = 'info'
ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

KUBECONFIG = os.getenv('KUBECONFIG', None)
DRY_RUN = os.getenv('DRY_RUN', None)

default_env = os.getenv('ENV', 'dev')
work_path = os.path.join(ROOT_PATH, default_env, 'k8s')
kubeconfig_dir = os.path.join(work_path, 'kubeconfig')
accounts_file = os.path.join(work_path, 'accounts.yml')
k8s_apply_script = os.path.join(ROOT_PATH, 'bin', 'k8s_account.sh')
k8s_apply_cluster_admin_script = os.path.join(ROOT_PATH, 'bin', 'k8s_cluster_admin.sh')
create_kubeconfig_script = os.path.join(ROOT_PATH, 'bin', 'create_kubeconfig.sh')


def die(msg, exitCode=1):
    print(msg)
    os.exit(exitCode)


def action(cmd):
    rc  = 0
    if DRY_RUN is not None:
        print('/*******************      DRY RUN        ****************************/')
        print(cmd)
        print('/*******************      DRY RUN        ****************************/')
    else:
        rc = call(cmd, shell=True)
        print(rc)

    return rc


def log(msg, level=INFO):
    print(msg)


def apply_project(project):
    namespace = None

    if 'namespace' in project:
        namespace = project['namespace']

    apply_accounts(project['accounts'], namespace)


def apply_accounts(accounts, namespace=None):
    for account in accounts:
        log('Apply account %s' % account['name'])
        envVars  = ' KUBECONFIG=' + KUBECONFIG
        envVars += ' KUBE_SERVICEACCOUNT=' + account['name']
        envVars += ' KUBE_ROLE_NAME=' + account['role']

        script = k8s_apply_script
        if account['role'] == 'cluster-admin':
            script = k8s_apply_cluster_admin_script

        if 'namespace' in account:
            namespace = account['namespace']
        if namespace is not None:
            envVars += ' KUBE_NAMESPACE=' + namespace
        cmd = ' '.join(['env', envVars, 'bash', script])
        arc = action(cmd)

        if arc == 0:
            create_kubeconfig(account, namespace)


def create_kubeconfig(account, namespace=None):
    log('Create KUBECONFIG for account %s' % account['name'])
    envVars  = ' KUBECONFIG_DIR=' + kubeconfig_dir
    envVars += ' KUBE_SERVICEACCOUNT=' + account['name']
    if namespace is not None:
        envVars += ' KUBE_NAMESPACE=' + namespace
    cmd = ' '.join(['env', envVars, 'bash', create_kubeconfig_script])
    arc = action(cmd)


########################################################################


if KUBECONFIG is None:
    die('KUBECONFIG environment variable is required!', 2)

if not os.path.isfile(KUBECONFIG):
    die('KUBECONFIG environment variable is required!', 3)

with open(accounts_file, 'r') as stream:
    try:
        apply_project(yaml.safe_load(stream))
    except yaml.YAMLError as exc:
        print(exc)
