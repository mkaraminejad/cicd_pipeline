import os

f = open('test-login-app/Chart.yaml','r')
lines = f.readlines()
for row in lines:
    if row.startswith("name"):
        chart=row
    if row.startswith("version"):
        version=row


chart_name=chart.split(" ")
ver=version.split(" ")
package=chart_name[1].strip()+'-'+ver[1].strip()+'.tgz'
print(package)        
f.close()


