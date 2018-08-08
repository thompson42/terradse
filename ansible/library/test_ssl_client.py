
import ssl
from dse.cluster import Cluster
from dse.auth import PlainTextAuthProvider
from dse.query import dict_factory

session = None
ssl_options=dict(certfile='/etc/ssl/SelfSignRootCA/SelfSignRootCA.pem', keyfile='/etc/ssl/SelfSignRootCA/SelfSignRootCA.key', ssl_version=ssl.PROTOCOL_TLSv1)


is_ssl             = True
is_login_required  = True
login_user         = 'TestAdmin'
login_password     = 'TestAdminPassword'
login_hosts        = '10.200.176.188'
login_port         = '9042'

try:
    if not is_login_required:
        cluster = Cluster([login_hosts], port=login_port)

    else:
        auth_provider = PlainTextAuthProvider(username=login_user, password=login_password)
        
        if is_ssl:
            cluster = Cluster([login_hosts], auth_provider=auth_provider, protocol_version=3.3, port=login_port, ssl_options=ssl_options)
        else:
            cluster = Cluster([login_hosts], auth_provider=auth_provider, protocol_version=3.3, port=login_port)
        
    session = cluster.connect()
    session.row_factory = dict_factory
    
except Exception, e:
    print(e.message)
        
try:
    query_str = "SELECT * FROM SYSTEM_AUTH.roles"
    result = session.execute(query_str)
    test = 1
except Exception, e:
    print(e.message)
