# deep-fp16
Jupyter + Apex + Pytorch with nvidia fixes
## How to Run:
```
docker run -d --gpus=all --ipc=host -p 6006:6006 -p 8888:8888 -v /some-fast-storage:/workspace/notebooks -v /some-large-storage:/workspace/data --restart=always rexhaif/deep-fp16:latest
```
