# Image Processing in the Browser with Nx — Presentation

This folder contains a [Reveal.js](https://revealjs.com/) slideshow for the talk "Image Processing in the Browser with Nx".

## How to Run

1. Install dependencies (already done):

   ```sh
   npm install
   ```

2. Start a local web server in this folder. For example:

   ```sh
   npx server .
   # or
   python3 -m http.server 8000
   ```

3. Open [http://localhost:8000/index.html](http://localhost:8000/index.html) in your browser.

## Adding a Video

- Place your `.mp4` file in the `videos/` folder.
- Update the `<source src="videos/sample.mp4" ...>` in `index.html` if you use a different filename.

## Configuring the IFrame URL

- By default, the iframe slide loads `http://localhost:8080`.
- To use a different URL, add `?iframe_url=YOUR_URL` to the browser address bar, e.g.:

  ```
  http://localhost:8000/index.html?iframe_url=http://localhost:1234
  ```

---

Feel free to edit the slides in `index.html` as needed!
