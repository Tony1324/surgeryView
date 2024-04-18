import socket

host = "127.0.0.1"
port = 8267

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as socket:
    socket.bind((host,port))
    socket.listen()
    connection, address = socket.accept()
    with connection:
        print(f"connected from {address}")
        while True:
            data = connection.recv(1024)
            print("data received")
            if not data:
                break
            connection.sendall(data)
