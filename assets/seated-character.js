// Sitting character on top of the "My games" panel.
// Loads the rigged Godette model with its mixamo animation (gaming.fbx) and loops it.
import * as THREE from 'three';
import { FBXLoader } from 'three/addons/loaders/FBXLoader.js';

const host = document.getElementById('games-seat');
if (host) {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  host.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(28, 1, 0.1, 100);
  camera.position.set(0, 0.6, 2.5);
  camera.lookAt(0, 0.5, 0);

  scene.add(new THREE.HemisphereLight(0xffffff, 0x445566, 2.2));
  const key = new THREE.DirectionalLight(0xffffff, 2.4);
  key.position.set(2, 3, 3);
  scene.add(key);

  const resize = () => {
    const w = host.clientWidth;
    const h = host.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  };
  resize();
  new ResizeObserver(resize).observe(host);

  const texLoader = new THREE.TextureLoader();
  const skinTex = texLoader.load('assets/godette/godette.png');
  skinTex.colorSpace = THREE.SRGBColorSpace;

  let mixer = null;
  const clock = new THREE.Clock();

  new FBXLoader().load(
    'assets/godette/gaming.fbx',
    (model) => {
      model.scale.setScalar(0.01);
      model.traverse((child) => {
        if (child.isMesh) {
          child.frustumCulled = false;
          child.material = new THREE.MeshStandardMaterial({ map: skinTex, roughness: 0.8, skinning: true });
        }
      });

      // Normalise: feet on y=0, centred on x/z, height 1.
      const box = new THREE.Box3().setFromObject(model);
      const size = box.getSize(new THREE.Vector3());
      const k = 1 / size.y;
      model.scale.multiplyScalar(k);
      box.setFromObject(model);
      const center = box.getCenter(new THREE.Vector3());
      model.position.x -= center.x;
      model.position.z -= center.z;
      model.position.y -= box.min.y;
      scene.add(model);

      if (model.animations.length) {
        mixer = new THREE.AnimationMixer(model);
        const action = mixer.clipAction(model.animations[0]);
        action.play();
        if (reduceMotion) {
          mixer.update(1.0);
          mixer.timeScale = 0;
        }
      }
      if (reduceMotion) renderer.render(scene, camera);
      else requestAnimationFrame(loop);
    },
    undefined,
    () => host.remove(),
  );

  let visible = true;
  new IntersectionObserver((entries) => {
    visible = entries[0].isIntersecting;
  }).observe(host);

  function loop() {
    requestAnimationFrame(loop);
    if (!visible) {
      clock.getDelta();
      return;
    }
    if (mixer) mixer.update(clock.getDelta());
    renderer.render(scene, camera);
  }
}
