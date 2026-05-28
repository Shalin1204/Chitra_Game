/**
 * throttle — limits how often fn can be called.
 * @param {Function} fn
 * @param {number} limitMs
 */
function throttle(fn, limitMs) {
  let last = 0;
  return function (...args) {
    const now = Date.now();
    if (now - last >= limitMs) {
      last = now;
      fn.apply(this, args);
    }
  };
}

module.exports = { throttle };