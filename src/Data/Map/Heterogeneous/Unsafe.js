"use strict";

exports.unsafeGet = function (wrap) {
  return function (fallback) {
    return function (label) {
      return function (map) {
        if ({}.hasOwnProperty.call(map, label)) {
          return wrap(map[label]);
        }
        return fallback;
      };
    };
  };
};

exports.unsafeDelete = function (label) {
  return function (map) {
    var copy = {};
    for (var key in map) {
      if (key !== label && {}.hasOwnProperty.call(map, key)) {
        copy[key] = map[key];
      }
    }
    return copy;
  };
};

exports.unsafeSet = function (label) {
  return function (value) {
    return function (map) {
      var copy = {};
      for (var key in map) {
        if ({}.hasOwnProperty.call(map, key)) {
          copy[key] = map[key];
        }
      }
      copy[label] = value;
      return copy;
    };
  };
};

exports.unsafeMember = function (label) {
  return function (map) {
    return {}.hasOwnProperty.call(map, label);
  };
};

exports.unsafeSize = function (map) {
  return Object.keys(map).length;
};

exports.unsafeEmpty = {};

exports.unsafeUnion = function (map1) {
  return function (map2) {
    var union = {};
    for (var key in map1) {
      if ({}.hasOwnProperty.call(map1, key)) {
        union[key] = map1[key];
      }
    }
    for (var key in map2) {
      if ({}.hasOwnProperty.call(map2, key)) {
        union[key] = map2[key];
      }
    }
    return union;
  };
};
