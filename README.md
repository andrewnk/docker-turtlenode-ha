# Docker Turtle Node

This is a docker image that builds the [TurtleCoin daemon](https://github.com/turtlecoin/turtlecoin) and the [TurtleCoind High-Availability Daemon Wrapper](https://github.com/turtlecoin/turtlecoind-ha), making it easy to spin up a public node. 

### Installing and Running
First clone the repo:
```sh
git clone https://github.com/andrewnk/docker-turtlenode-ha.git
cd docker-turtlenode-ha
```

Then build the image using your wallet address and the fee you would like to charge for transactions:
```sh
docker build --build-arg WALLET=mywalletaddress --build-arg FEE=1000 -t turtlenode .
```

Finally, run the container (exposing the necessary ports):
```sh
docker run -d -p 11898:11898 -p 11897:11897 --name turtlenode turtlenode
```

You can view the logs in docker using:
```sh
docker logs turtlenode
```

or watch them directly from pm2
```sh
docker exec turtlenode pm2 logs
```

TODO:
 - Add a web interface for minitoring, such as [pm2-gui](https://github.com/Tjatse/pm2-gui)
 
License
----
MIT