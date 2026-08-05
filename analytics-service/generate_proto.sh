#!/bin/bash
# Ejecutar desde la raíz de analytics-service/
# Genera los archivos Python desde checkpoints.proto

echo "Generando archivos proto para Python..."

pip install grpcio-tools --quiet

python -m grpc_tools.protoc \
    --proto_path=../proto \
    --python_out=app/grpc \
    --grpc_python_out=app/grpc \
    ../proto/checkpoints.proto

echo "✅ Archivos generados:"
echo "   app/grpc/checkpoints_pb2.py"
echo "   app/grpc/checkpoints_pb2_grpc.py"
