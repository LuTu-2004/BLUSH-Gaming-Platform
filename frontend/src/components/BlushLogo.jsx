import React from 'react';

export default function BlushLogo({ size = 32, showBg = true, stroke = '#D91E5B', bg = '#FFAEC9', style }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ display: 'inline-block', verticalAlign: 'middle', ...style }}
    >
      {/* Pink background circle */}
      {showBg && (
        <circle
          cx="50"
          cy="50"
          r="46"
          fill={bg}
        />
      )}
      
      {/* Top arch (H's top / left heart lobe) */}
      <path
        d="M 32,38 C 32,22 48,22 48,38"
        stroke={stroke}
        strokeWidth="8.5"
        strokeLinecap="round"
        fill="none"
      />

      {/* Left vertical stem & bottom L crossbar */}
      <path
        d="M 32,32 L 32,72 L 46,72"
        stroke={stroke}
        strokeWidth="8.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />

      {/* Crossbar of H */}
      <path
        d="M 32,54 L 48,54"
        stroke={stroke}
        strokeWidth="8.5"
        strokeLinecap="round"
        fill="none"
      />

      {/* Right vertical stem of H */}
      <path
        d="M 48,48 L 48,72"
        stroke={stroke}
        strokeWidth="8.5"
        strokeLinecap="round"
        fill="none"
      />

      {/* D loop (right heart lobe) with bottom curve for heart shape */}
      <path
        d="M 48,54 C 64,54 72,58 72,68 C 72,78 62,78 50,72"
        stroke={stroke}
        strokeWidth="8.5"
        strokeLinecap="round"
        fill="none"
      />
    </svg>
  );
}
