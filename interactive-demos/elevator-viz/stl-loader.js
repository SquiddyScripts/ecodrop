/**
 * Load binary STLs via THREE.STLLoader, center geometry, detect orientation.
 */
(function (global) {
  const loader = new THREE.STLLoader();

  function solidFromGeometry(geo) {
    geo = geo.index ? geo.toNonIndexed() : geo.clone();
    geo.computeBoundingBox();
    const bb = geo.boundingBox;
    const center = new THREE.Vector3();
    const size = new THREE.Vector3();
    bb.getCenter(center);
    bb.getSize(size);
    geo.translate(-center.x, -center.y, -center.z);

    const sz = [size.x, size.y, size.z];
    const maxSpan = Math.max(sz[0], sz[1], sz[2]);
    const upAxis = sz.indexOf(maxSpan);

    return {
      geo,
      size: sz,
      upAxis,
      maxSpan,
      units: maxSpan > 20 ? 'mm' : 'normalized',
    };
  }

  function loadSolid(url) {
    return new Promise((resolve, reject) => {
      loader.load(
        url,
        (geo) => resolve(solidFromGeometry(geo)),
        undefined,
        (err) => reject(new Error('STL failed: ' + url + ' — ' + err))
      );
    });
  }

  const CATALOG = {
    cab: 'Ensamble cabina (paneles + techo).stl',
    barbell: 'BARBELL ASSEMBLY.stl',
    varcwt: 'varaible counterweight.stl',
    ram: 'User Library-Ram Head 30 dbg.STL',
    roller: 'User Library-roller guide assembly_b.STL',
  };

  global.loadVcwtParts = async function loadVcwtParts(baseUrl) {
    const base = baseUrl.replace(/\/?$/, '/');
    const out = {};
    const names = Object.keys(CATALOG);
    const loadEl = document.getElementById('load');
    const loadTxt = loadEl && loadEl.querySelector('.t');

    for (let i = 0; i < names.length; i++) {
      const key = names[i];
      const file = CATALOG[key];
      if (loadTxt) loadTxt.textContent = 'LOADING CAD (' + (i + 1) + '/' + names.length + '): ' + key;
      out[key] = await loadSolid(base + encodeURI(file));
    }
    return out;
  };
})(window);
