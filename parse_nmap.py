import sys
import xml.etree.ElementTree as ET

xml_file = sys.argv[1]
tree = ET.parse(xml_file)
root = tree.getroot()

for host in root.findall('host'):
    address = host.find('address').get('addr')
    print(f"Host: {address}")
    for port in host.findall('.//port'):
        portid = port.get('portid')
        state = port.find('state').get('state')
        service = port.find('service')
        if service is not None:
            service_name = service.get('name', 'unknown')
            product = service.get('product', '')
            tunnel = service.get('tunnel', '')
            label = service_name
            if tunnel:
                label = f"{tunnel}/{label}"  # e.g. ssl/http
            if product:
                label += f" — {product}"
        else:
            label = 'unknown'
        print(f"  Port {portid}: {state} ({label})")
