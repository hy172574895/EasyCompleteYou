import sys
temp = sys.stdin.readline()
# temp = input()
print(type(temp))
data_bytes   = bytes(temp, encoding = "UTF-8")
part_bytes    = data_bytes.split(b'\n')
print(part_bytes)
print(len(data_bytes))
