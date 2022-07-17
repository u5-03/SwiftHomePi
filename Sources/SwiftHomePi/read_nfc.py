import nfc
import binascii

def read_id():
    print("Touch!")
    clf = nfc.ContactlessFrontend("usb")
    tag = clf.connect(rdwr={'on-connect': lambda tag: False})
    tag_id = binascii.hexlify(tag._nfcid).decode()
    clf.close()
    return tag_id
