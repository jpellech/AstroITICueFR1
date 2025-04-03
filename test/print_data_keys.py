import tdt

path = "(3L)ABC8L-250321-155842"
print("finding epocs from", path)
data = tdt.read_block(path)


if "epocs" in data.keys():
    print("Epochs found:", data["epocs"].keys())

    """
    for key, value in data["epocs"].items():
        print(f"\nEpoch: {key}")
        print("Timestamps:", value["onset"][:10])
        print("Offsets:", value["offset"][:10])
        # print("Values:", value["data"][:10])
    """

else:
    print("No epoch data found.")
