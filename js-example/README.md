# mocap4face Web Demo

1. Open the sample project in an editor of your choice
2. Run `npm install && npm run dev` to start a local server with the demo
3. Run `npm install && npm run dev_https` to start a local server with self-signed HTTPS support
4. Run `npm install @facemoji/mocap4face` in your own project to add mocap4face as a dependency

If the webcamera button is not working, you might need to use HTTPS for the local dev server.
Run `npm run dev_https` and allow the self-signed certificate in the browser to start the demo in HTTPS mode.

You can also run `npm run build` to create a production bundle of the demo app.
