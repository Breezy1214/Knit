"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[9671],{3905:(e,t,r)=>{r.d(t,{Zo:()=>d,kt:()=>b});var n=r(67294);function o(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function i(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function a(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?i(Object(r),!0).forEach((function(t){o(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):i(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function l(e,t){if(null==e)return{};var r,n,o=function(e,t){if(null==e)return{};var r,n,o={},i=Object.keys(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||(o[r]=e[r]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(o[r]=e[r])}return o}var s=n.createContext({}),c=function(e){var t=n.useContext(s),r=t;return e&&(r="function"==typeof e?e(t):a(a({},t),e)),r},d=function(e){var t=c(e.components);return n.createElement(s.Provider,{value:t},e.children)},u="mdxType",p={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},f=n.forwardRef((function(e,t){var r=e.components,o=e.mdxType,i=e.originalType,s=e.parentName,d=l(e,["components","mdxType","originalType","parentName"]),u=c(r),f=o,b=u["".concat(s,".").concat(f)]||u[f]||p[f]||i;return r?n.createElement(b,a(a({ref:t},d),{},{components:r})):n.createElement(b,a({ref:t},d))}));function b(e,t){var r=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=r.length,a=new Array(i);a[0]=f;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[u]="string"==typeof e?e:o,a[1]=l;for(var c=2;c<i;c++)a[c]=r[c];return n.createElement.apply(null,a)}return n.createElement.apply(null,r)}f.displayName="MDXCreateElement"},59881:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>s,contentTitle:()=>a,default:()=>p,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var n=r(87462),o=(r(67294),r(3905));const i={sidebar_position:1},a="About",l={unversionedId:"intro",id:"intro",title:"About",description:"A lightweight framework that simplifies communication between core parts of your Roblox experience and seamlessly bridges the gap between the server and the client.",source:"@site/docs/intro.md",sourceDirName:".",slug:"/intro",permalink:"/Knit/docs/intro",draft:!1,editUrl:"https://github.com/Breezy1214/Knit/edit/master/docs/intro.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1},sidebar:"defaultSidebar",next:{title:"Getting Started",permalink:"/Knit/docs/gettingstarted"}},s={},c=[{value:"Why Choose Knit?",id:"why-choose-knit",level:2},{value:"Structure",id:"structure",level:3},{value:"Networking Layer",id:"networking-layer",level:3},{value:"Extensible",id:"extensible",level:3},{value:"For Everyone",id:"for-everyone",level:3},{value:"Widely Used",id:"widely-used",level:3}],d={toc:c},u="wrapper";function p(e){let{components:t,...r}=e;return(0,o.kt)(u,(0,n.Z)({},d,r,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"about"},"About"),(0,o.kt)("p",null,"A lightweight framework that simplifies communication between core parts of your Roblox experience and seamlessly bridges the gap between the server and the client."),(0,o.kt)("p",null,"See the ",(0,o.kt)("a",{parentName:"p",href:"/Knit/docs/gettingstarted"},"Getting Started")," guide to start using Knit."),(0,o.kt)("h2",{id:"why-choose-knit"},"Why Choose Knit?"),(0,o.kt)("h3",{id:"structure"},"Structure"),(0,o.kt)("p",null,"Services and controllers are the core of Knit. These objects provide a foundation for Roblox experiences. By orienting core game logic around services and controllers, developers will inherit cleaner organization across codebases and easier maintainability. Services and controllers are easy to create, and provide a built-in networking layer."),(0,o.kt)("h3",{id:"networking-layer"},"Networking Layer"),(0,o.kt)("p",null,"Knit automatically provides networking between the client and services. Since Knit handles the networking infrastructure, developers are not left with the burden of manually creating RemoteEvent and RemoteFunction objects throughout the hierarchy. Each service has the ability to expose specific endpoints to the client through declarative code."),(0,o.kt)("h3",{id:"extensible"},"Extensible"),(0,o.kt)("p",null,"Knit is built to be extensible. Developers write their own bootstrapping code to start and configure Knit, which gives developers the freedom to extend how Knit functions."),(0,o.kt)("h3",{id:"for-everyone"},"For Everyone"),(0,o.kt)("p",null,"From professional game studios to independent developers, Knit offers a powerful and easy-to-use foundation for Roblox experiences. Knit is available from both Wally and from the Roblox library, allowing developers to choose between a Rojo-based or Studio-based workflow."),(0,o.kt)("h3",{id:"widely-used"},"Widely Used"),(0,o.kt)("p",null,"Knit has been battle-tested in the Roblox ecosystem, and has proven itself to be reliable in both stability and scale. Knit is also open-source and encourages developers to contribute to the growth of the framework."))}p.isMDXComponent=!0}}]);