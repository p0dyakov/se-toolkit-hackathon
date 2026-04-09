<script lang="ts">
	import { onMount } from 'svelte';

	let container = $state<HTMLDivElement | null>(null);

	onMount(() => {
		let mounted = true;
		let cleanup: (() => void) | undefined;

		async function mountGradient() {
			if (!container) return;

			const React = await import('react');
			const { createRoot } = await import('react-dom/client');
			const { ShaderGradient, ShaderGradientCanvas } = await import('@shadergradient/react');

			if (!mounted || !container) return;

			const root = createRoot(container);
			const shaderCanvasProps: Record<string, unknown> = {
				pointerEvents: 'none',
				style: {
					width: '100%',
					height: '100%'
				},
				className: 'pointer-events-none'
			};
			const shaderProps: Record<string, unknown> = {
				animate: 'on',
				axesHelper: 'off',
				bgColor1: '#000000',
				bgColor2: '#000000',
				brightness: 0.8,
				cAzimuthAngle: 270,
				cDistance: 0.5,
				cPolarAngle: 180,
				cameraZoom: 15.1,
				color1: '#73bfc4',
				color2: '#ff810a',
				color3: '#8da0ce',
				control: 'props',
				destination: 'onCanvas',
				embedMode: 'off',
				envPreset: 'city',
				format: 'gif',
				frameRate: 10,
				gizmoHelper: 'hide',
				grain: 'on',
				lightType: 'env',
				pixelDensity: 1,
				positionX: -0.1,
				positionY: 0,
				positionZ: 0,
				range: 'disabled',
				rangeEnd: 40,
				rangeStart: 0,
				reflection: 0.4,
				rotationX: 0,
				rotationY: 130,
				rotationZ: 70,
				shader: 'defaults',
				type: 'sphere',
				uAmplitude: 3.2,
				uDensity: 0.8,
				uFrequency: 5.5,
				uSpeed: 0.08,
				uStrength: 0.3,
				uTime: 0,
				wireframe: false
			};

			root.render(
				React.createElement(
					ShaderGradientCanvas as unknown as Parameters<typeof React.createElement>[0],
					shaderCanvasProps,
					React.createElement(
						ShaderGradient as unknown as Parameters<typeof React.createElement>[0],
						shaderProps
					)
				)
			);

			cleanup = () => root.unmount();
		}

		void mountGradient();

		return () => {
			mounted = false;
			cleanup?.();
		};
	});
</script>

<div bind:this={container} class="pointer-events-none absolute inset-0" aria-hidden="true"></div>
