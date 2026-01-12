import React, { useState, useEffect, useRef, useMemo } from 'react';
import { Send, MapPin, Navigation, Calculator, MessageSquare, X, User, LogOut, Star, History, Home, Briefcase, Clock, TrendingDown, Zap } from 'lucide-react';

export default function RutaAssistant() {
  // Chat states
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content: '¡Hola! Soy tu asistente de rutas. ¿Necesitas un viaje o un envío?'
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [geo, setGeo] = useState(null);
  const [geoLoading, setGeoLoading] = useState(false);
  const [showChat, setShowChat] = useState(false);

  // User state
  const [currentUser, setCurrentUser] = useState(null);
  const [showLogin, setShowLogin] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const [userEmail, setUserEmail] = useState('');
  const [userName, setUserName] = useState('');
  const [homeAddress, setHomeAddress] = useState('');
  const [officeAddress, setOfficeAddress] = useState('');

  // Search fields
  const [serviceType, setServiceType] = useState('transport');
  const [country, setCountry] = useState('colombia');
  const [origin, setOrigin] = useState('');
  const [destination, setDestination] = useState('');
  const [originSuggestions, setOriginSuggestions] = useState([]);
  const [destSuggestions, setDestSuggestions] = useState([]);
  const [showOriginSuggestions, setShowOriginSuggestions] = useState(false);
  const [showDestSuggestions, setShowDestSuggestions] = useState(false);
  const [calculated, setCalculated] = useState(false);
  const [distance, setDistance] = useState(null);

  // Results and filters
  const [sortBy, setSortBy] = useState('default');
  const [results, setResults] = useState([]);

  // History and favorites
  const [history, setHistory] = useState([]);
  const [favorites, setFavorites] = useState([]);

  // Google Places
  const [autocompleteService, setAutocompleteService] = useState(null);

  const messagesEndRef = useRef(null);

  // Services configuration
  const servicesConfig = {
    colombia: {
      currency: 'COP',
      baseDistance: 5,
      services: [
        {
          name: 'taxi',
          displayName: 'Taxi',
          color: '#FFC107',
          types: [{ name: 'Taxi', basePrice: 5000, pricePerKm: 1300, eta: 8 }]
        },
        {
          name: 'uber',
          displayName: 'Uber',
          color: '#000000',
          types: [
            { name: 'UberX', basePrice: 4000, pricePerKm: 1000, eta: 10 },
            { name: 'Comfort', basePrice: 5000, pricePerKm: 1200, eta: 8 },
            { name: 'UberXL', basePrice: 6000, pricePerKm: 1500, eta: 15 }
          ]
        },
        {
          name: 'didi',
          displayName: 'DiDi',
          color: '#FF6600',
          types: [
            { name: 'Express', basePrice: 3800, pricePerKm: 900, eta: 12 },
            { name: 'Comfort', basePrice: 4500, pricePerKm: 1100, eta: 10 }
          ]
        },
        {
          name: 'cabify',
          displayName: 'Cabify',
          color: '#6B2C91',
          types: [
            { name: 'Lite', basePrice: 4000, pricePerKm: 1000, eta: 9 },
            { name: 'Executive', basePrice: 6000, pricePerKm: 1400, eta: 7 }
          ]
        },
        {
          name: 'indrive',
          displayName: 'inDrive',
          color: '#1DCC70',
          types: [
            { name: 'Economy', basePrice: 3500, pricePerKm: 850, eta: 13 },
            { name: 'Standard', basePrice: 4200, pricePerKm: 1000, eta: 11 }
          ]
        },
        {
          name: 'yango',
          displayName: 'Yango',
          color: '#FC3F1D',
          types: [
            { name: 'Economy', basePrice: 3600, pricePerKm: 880, eta: 12 },
            { name: 'Comfort', basePrice: 4300, pricePerKm: 1050, eta: 10 }
          ]
        }
      ]
    },
    mexico: {
      currency: 'MXN',
      baseDistance: 5,
      services: [
        {
          name: 'taxi',
          displayName: 'Taxi',
          color: '#FFC107',
          types: [{ name: 'Taxi', basePrice: 50, pricePerKm: 15, eta: 8 }]
        },
        {
          name: 'uber',
          displayName: 'Uber',
          color: '#000000',
          types: [
            { name: 'UberX', basePrice: 40, pricePerKm: 12, eta: 10 },
            { name: 'Comfort', basePrice: 55, pricePerKm: 15, eta: 8 }
          ]
        },
        {
          name: 'didi',
          displayName: 'DiDi',
          color: '#FF6600',
          types: [
            { name: 'Express', basePrice: 38, pricePerKm: 11, eta: 12 }
          ]
        },
        {
          name: 'cabify',
          displayName: 'Cabify',
          color: '#6B2C91',
          types: [
            { name: 'Lite', basePrice: 40, pricePerKm: 12, eta: 9 }
          ]
        },
        {
          name: 'indrive',
          displayName: 'inDrive',
          color: '#1DCC70',
          types: [
            { name: 'Economy', basePrice: 35, pricePerKm: 10, eta: 13 }
          ]
        },
        {
          name: 'yango',
          displayName: 'Yango',
          color: '#FC3F1D',
          types: [
            { name: 'Economy', basePrice: 36, pricePerKm: 10.5, eta: 12 }
          ]
        }
      ]
    },
    peru: {
      currency: 'PEN',
      baseDistance: 5,
      services: [
        {
          name: 'taxi',
          displayName: 'Taxi',
          color: '#FFC107',
          types: [{ name: 'Taxi', basePrice: 8, pricePerKm: 2.5, eta: 8 }]
        },
        {
          name: 'uber',
          displayName: 'Uber',
          color: '#000000',
          types: [
            { name: 'UberX', basePrice: 6, pricePerKm: 2, eta: 10 }
          ]
        },
        {
          name: 'didi',
          displayName: 'DiDi',
          color: '#FF6600',
          types: [
            { name: 'Express', basePrice: 5.5, pricePerKm: 1.8, eta: 12 }
          ]
        },
        {
          name: 'cabify',
          displayName: 'Cabify',
          color: '#6B2C91',
          types: [
            { name: 'Lite', basePrice: 6, pricePerKm: 2, eta: 9 }
          ]
        },
        {
          name: 'indrive',
          displayName: 'inDrive',
          color: '#1DCC70',
          types: [
            { name: 'Economy', basePrice: 5, pricePerKm: 1.7, eta: 13 }
          ]
        },
        {
          name: 'yango',
          displayName: 'Yango',
          color: '#FC3F1D',
          types: [
            { name: 'Economy', basePrice: 5.2, pricePerKm: 1.75, eta: 12 }
          ]
        }
      ]
    }
  };

  // POIs massive list
  const poisByCity = {
    bogota: [
      "Aeropuerto El Dorado (BOG)",
      "Terminal de Transporte Salitre",
      "Terminal del Sur",
      "Terminal del Norte",
      "Parque 93",
      "Zona T",
      "Centro Comercial Andino",
      "Unicentro Bogotá",
      "Centro Mayor",
      "Gran Estación",
      "Santafé",
      "Titán Plaza",
      "Portal 80",
      "Fontanar",
      "Monserrate",
      "Museo del Oro",
      "Plaza de Bolívar",
      "Museo Botero",
      "La Candelaria",
      "Universidad de los Andes",
      "Universidad Nacional",
      "Universidad Javeriana",
      "Universidad del Rosario",
      "Corferias",
      "Movistar Arena",
      "Estadio El Campín",
      "Hospital El Country",
      "Hospital Santa Fe",
      "Clínica del Country",
      "Clínica Shaio",
      "Usaquén",
      "Chapinero",
      "Chicó",
      "Cedritos",
      "Suba Centro",
      "Centro Internacional",
      "Parque Simón Bolívar"
    ],
    cdmx: [
      "Aeropuerto Internacional CDMX (AICM)",
      "Aeropuerto Felipe Ángeles (AIFA)",
      "Terminal Central del Norte",
      "Terminal TAPO",
      "Terminal del Sur",
      "Terminal Observatorio",
      "Ángel de la Independencia",
      "Palacio de Bellas Artes",
      "Zócalo",
      "Monumento a la Revolución",
      "Polanco",
      "Condesa",
      "Roma Norte",
      "Coyoacán",
      "Centro Santa Fe",
      "Antara Polanco",
      "Perisur",
      "Parque Delta",
      "UNAM Ciudad Universitaria",
      "IPN Zacatenco",
      "Tec de Monterrey Santa Fe",
      "Estadio Azteca",
      "Arena CDMX",
      "Auditorio Nacional",
      "Museo Nacional de Antropología",
      "Museo Frida Kahlo",
      "Museo Soumaya",
      "Chapultepec",
      "Xochimilco",
      "Basílica de Guadalupe",
      "WTC México",
      "Torre Mayor",
      "Reforma 222"
    ],
    lima: [
      "Aeropuerto Jorge Chávez",
      "Plaza Norte",
      "Jockey Plaza",
      "Larcomar",
      "Real Plaza Salaverry",
      "MegaPlaza",
      "Miraflores",
      "San Isidro",
      "Barranco",
      "Surco",
      "La Molina",
      "Plaza de Armas Lima",
      "Parque Kennedy",
      "Costa Verde",
      "Malecón Miraflores",
      "Puente de los Suspiros",
      "Circuito Mágico del Agua",
      "Huaca Pucllana",
      "PUCP",
      "UPC Monterrico",
      "Universidad de Lima",
      "UNMSM",
      "Clínica Anglo Americana",
      "Clínica Ricardo Palma",
      "Hospital Rebagliati",
      "Estadio Nacional"
    ]
  };

  const getPois = () => {
    if (country === 'colombia') return poisByCity.bogota;
    if (country === 'mexico') return poisByCity.cdmx;
    if (country === 'peru') return poisByCity.lima;
    return [];
  };

  // Initialize Google Places
  useEffect(() => {
    if (window.google && window.google.maps && window.google.maps.places) {
      const service = new window.google.maps.places.AutocompleteService();
      setAutocompleteService(service);
    }
  }, []);

  // Load user
  useEffect(() => {
    const savedUser = localStorage.getItem('rutaOraculo_user');
    if (savedUser) {
      try {
        const user = JSON.parse(savedUser);
        setCurrentUser(user);
        setHomeAddress(user.homeAddress || '');
        setOfficeAddress(user.officeAddress || '');

        const savedHistory = localStorage.getItem(`rutaOraculo_history_${user.id}`);
        if (savedHistory) setHistory(JSON.parse(savedHistory));

        const savedFavorites = localStorage.getItem(`rutaOraculo_favorites_${user.id}`);
        if (savedFavorites) setFavorites(JSON.parse(savedFavorites));
      } catch (e) {
        console.error('Error loading user', e);
      }
    }
  }, []);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Google Places Autocomplete
  const searchPlaces = (value, callback) => {
    if (!value || value.length < 3) {
      callback([]);
      return;
    }

    if (autocompleteService) {
      const countryCode = country === 'colombia' ? 'co' : country === 'mexico' ? 'mx' : 'pe';

      autocompleteService.getPlacePredictions(
        {
          input: value,
          componentRestrictions: { country: countryCode },
        },
        (predictions, status) => {
          if (status === window.google.maps.places.PlacesServiceStatus.OK && predictions) {
            const results = predictions.slice(0, 8).map(p => p.description);
            callback(results);
          } else {
            const pois = getPois();
            const filtered = pois.filter(p => p.toLowerCase().includes(value.toLowerCase())).slice(0, 8);
            callback(filtered);
          }
        }
      );
    } else {
      const pois = getPois();
      const filtered = pois.filter(p => p.toLowerCase().includes(value.toLowerCase())).slice(0, 8);
      callback(filtered);
    }
  };

  const handleOriginChange = (e) => {
    const value = e.target.value;
    setOrigin(value);

    if (value.length >= 3) {
      searchPlaces(value, (results) => {
        setOriginSuggestions(results);
        setShowOriginSuggestions(results.length > 0);
      });
    } else {
      setOriginSuggestions([]);
      setShowOriginSuggestions(false);
    }
  };

  const handleDestChange = (e) => {
    const value = e.target.value;
    setDestination(value);

    if (value.length >= 3) {
      searchPlaces(value, (results) => {
        setDestSuggestions(results);
        setShowDestSuggestions(results.length > 0);
      });
    } else {
      setDestSuggestions([]);
      setShowDestSuggestions(false);
    }
  };

  const selectOriginSuggestion = (suggestion) => {
    setOrigin(suggestion);
    setShowOriginSuggestions(false);
  };

  const selectDestSuggestion = (suggestion) => {
    setDestination(suggestion);
    setShowDestSuggestions(false);
  };

  const getGeolocation = () => {
    setGeoLoading(true);
    if (!navigator.geolocation) {
      alert('Tu navegador no soporta geolocalización');
      setGeoLoading(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const location = {
          lat: position.coords.latitude,
          lon: position.coords.longitude,
          accuracy: position.coords.accuracy
        };
        setGeo(location);
        setOrigin('Mi ubicación actual');
        setGeoLoading(false);

        if (showChat) {
          setMessages(prev => [...prev, {
            role: 'system',
            content: `Ubicación detectada: ${location.lat.toFixed(4)}, ${location.lon.toFixed(4)}`
          }]);
        }
      },
      (error) => {
        alert('No se pudo obtener tu ubicación. Por favor, permite el acceso.');
        setGeoLoading(false);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    );
  };

  // Traffic
  const getTraffic = () => {
    const hour = new Date().getHours();
    if ((hour >= 6 && hour <= 9) || (hour >= 17 && hour <= 20)) {
      return {
        multiplier: 1.4,
        text: 'Tráfico alto en la ruta',
        color: '#FEE2E2',
        textColor: '#DC2626'
      };
    }
    if (hour >= 9 && hour <= 17) {
      return {
        multiplier: 1.15,
        text: 'Tráfico moderado',
        color: '#FEF3C7',
        textColor: '#D97706'
      };
    }
    return {
      multiplier: 1.0,
      text: 'Tráfico fluido',
      color: '#D1FAE5',
      textColor: '#059669'
    };
  };

  // Calculate price
  const calculatePrice = (service, type) => {
    if (!distance) return null;
    const traffic = getTraffic();
    const base = type.basePrice + (type.pricePerKm * distance);
    return Math.round(base * traffic.multiplier);
  };

  // Calculate ETA
  const calculateEta = (type) => {
    if (!distance) return type.eta;
    const traffic = getTraffic();
    const baseTime = distance * 3;
    return Math.round((baseTime + type.eta) * traffic.multiplier);
  };

  const handleCalculate = () => {
    if (!origin.trim() || !destination.trim()) {
      alert('Por favor completa origen y destino');
      return;
    }

    const config = servicesConfig[country];
    const baseDistance = config.baseDistance;
    const randomVariation = Math.random() * 5 + 3;
    const calculatedDistance = baseDistance + randomVariation;

    setDistance(calculatedDistance);
    setCalculated(true);

    // Build results
    const allResults = [];
    config.services.forEach(service => {
      service.types.forEach(type => {
        allResults.push({
          serviceName: service.name,
          displayName: service.displayName,
          typeName: type.name,
          color: service.color,
          price: calculatePrice(service, type),
          eta: calculateEta(type)
        });
      });
    });

    setResults(allResults);

    // Save to history
    if (currentUser) {
      const newRoute = {
        id: Date.now(),
        from: origin,
        to: destination,
        country,
        serviceType,
        timestamp: new Date().toISOString(),
        distance: calculatedDistance
      };

      const updatedHistory = [newRoute, ...history].slice(0, 20);
      setHistory(updatedHistory);
      localStorage.setItem(`rutaOraculo_history_${currentUser.id}`, JSON.stringify(updatedHistory));
    }
  };

  // Get cheapest and fastest
  const getCheapest = () => results.length ? results.reduce((min, r) => r.price < min.price ? r : min) : null;
  const getFastest = () => results.length ? results.reduce((min, r) => r.eta < min.eta ? r : min) : null;

  // Sort results
  const sortedResults = useMemo(() => {
    if (!results.length) return [];

    let sorted = [...results];

    switch (sortBy) {
      case 'price-asc':
        sorted.sort((a, b) => a.price - b.price);
        break;
      case 'time-asc':
        sorted.sort((a, b) => a.eta - b.eta);
        break;
      case 'for-me':
        if (currentUser && currentUser.bookingCount) {
          sorted.sort((a, b) => {
            const aCount = currentUser.bookingCount[a.serviceName] || 0;
            const bCount = currentUser.bookingCount[b.serviceName] || 0;
            if (aCount !== bCount) return bCount - aCount;
            return (a.price * 0.6 + a.eta * 0.4) - (b.price * 0.6 + b.eta * 0.4);
          });
        }
        break;
      default:
        break;
    }

    return sorted;
  }, [results, sortBy, currentUser]);

  // User login
  const handleLogin = () => {
    if (!userEmail.trim()) {
      alert('Por favor ingresa tu email');
      return;
    }

    const user = {
      id: `user_${Date.now()}`,
      email: userEmail.trim(),
      name: userName.trim() || userEmail.split('@')[0],
      homeAddress: '',
      officeAddress: '',
      createdAt: new Date().toISOString(),
      bookingCount: {}
    };

    setCurrentUser(user);
    localStorage.setItem('rutaOraculo_user', JSON.stringify(user));
    setShowLogin(false);
    setUserEmail('');
    setUserName('');
  };

  const handleLogout = () => {
    setCurrentUser(null);
    setHistory([]);
    setFavorites([]);
    localStorage.removeItem('rutaOraculo_user');
    setShowProfile(false);
  };

  const updateProfile = () => {
    if (!currentUser) return;

    const updatedUser = {
      ...currentUser,
      homeAddress,
      officeAddress
    };

    setCurrentUser(updatedUser);
    localStorage.setItem('rutaOraculo_user', JSON.stringify(updatedUser));
    alert('Perfil actualizado');
  };

  // Toggle favorite
  const toggleFavorite = (route) => {
    const isFav = favorites.some(f => f.id === route.id);
    let updatedFavorites;

    if (isFav) {
      updatedFavorites = favorites.filter(f => f.id !== route.id);
    } else {
      updatedFavorites = [...favorites, route];
    }

    setFavorites(updatedFavorites);
    if (currentUser) {
      localStorage.setItem(`rutaOraculo_favorites_${currentUser.id}`, JSON.stringify(updatedFavorites));
    }
  };

  // Load route
  const loadRoute = (route) => {
    setOrigin(route.from);
    setDestination(route.to);
    setCountry(route.country);
    setServiceType(route.serviceType);
    setDistance(null);
    setCalculated(false);
    setShowProfile(false);
    setTimeout(() => handleCalculate(), 200);
  };

  // Handle booking
  const handleBooking = (serviceName) => {
    if (currentUser) {
      const updated = {
        ...currentUser,
        bookingCount: {
          ...currentUser.bookingCount,
          [serviceName]: (currentUser.bookingCount[serviceName] || 0) + 1
        }
      };
      setCurrentUser(updated);
      localStorage.setItem('rutaOraculo_user', JSON.stringify(updated));
    }

    const links = {
      uber: 'https://m.uber.com/',
      didi: 'https://web.didiglobal.com/',
      cabify: 'https://cabify.com/',
      indrive: 'https://indrive.com/',
      yango: 'https://yango.com/',
      taxi: null
    };

    const link = links[serviceName];
    if (link) {
      window.open(link, '_blank');
    } else {
      alert('Llama un taxi local o usa una app de taxis de tu ciudad');
    }
  };

  const handleSend = async () => {
    if (!input.trim() || loading) return;

    const userMessage = input.trim();
    setInput('');

    setMessages(prev => [...prev, { role: 'user', content: userMessage }]);
    setLoading(true);

    setTimeout(() => {
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: '¡Entendido! Para ayudarte mejor, por favor usa el formulario de búsqueda arriba para ingresar tu origen y destino, y te mostraré todas las opciones disponibles con precios en tiempo real.'
      }]);
      setLoading(false);
    }, 1000);
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      {/* Header */}
      <div className="bg-slate-800/50 backdrop-blur-sm border-b border-slate-700 px-4 py-3 shadow-lg">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-blue-600 p-2 rounded-lg">
              <Navigation className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-white">🔮 Ruta Oráculo</h1>
              <p className="text-xs text-slate-400">Compara precios y tiempos en tiempo real</p>
            </div>
          </div>
        </div>
      </div>

      {/* Login Banner */}
      {!currentUser && (
        <div className="bg-gradient-to-r from-blue-600 to-purple-600 px-4 py-3 shadow-lg">
          <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
            <div className="flex-1 min-w-0 text-center sm:text-left">
              <p className="text-white font-bold text-sm">🔒 Estás en modo incógnito</p>
              <p className="text-blue-100 text-xs mt-1">Inicia sesión para desbloquear insights avanzados, historial y favoritos</p>
            </div>
            <button
              onClick={() => setShowLogin(true)}
              className="bg-white text-blue-600 px-4 py-2 rounded-lg font-bold text-sm whitespace-nowrap hover:bg-blue-50 transition-colors flex-shrink-0"
            >
              ✨ Iniciar sesión
            </button>
          </div>
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 overflow-y-auto px-4 py-6 pb-24">
        <div className="max-w-6xl mx-auto space-y-6">

          {/* Service Type */}
          <div>
            <div className="text-xs font-bold text-slate-400 mb-3 uppercase tracking-wide">
              Qué necesitas
            </div>
            <div className="grid grid-cols-3 gap-3">
              {['transport', 'moto', 'delivery'].map((type) => (
                <button
                  key={type}
                  onClick={() => {
                    setServiceType(type);
                    setCalculated(false);
                    setDistance(null);
                    setResults([]);
                  }}
                  className={`px-4 py-3 rounded-xl font-bold text-sm transition-all ${
                    serviceType === type
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/50'
                      : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                  }`}
                >
                  {type === 'transport' ? '🚗 Transporte' : type === 'moto' ? '🏍️ Moto' : '📦 Envío'}
                </button>
              ))}
            </div>
          </div>

          {/* Country */}
          <div>
            <div className="text-xs font-bold text-slate-400 mb-3 uppercase tracking-wide">
              País
            </div>
            <select
              value={country}
              onChange={(e) => {
                setCountry(e.target.value);
                setOrigin('');
                setDestination('');
                setCalculated(false);
                setDistance(null);
                setResults([]);
              }}
              className="w-full bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500 font-semibold"
            >
              <option value="colombia">🇨🇴 Colombia</option>
              <option value="mexico">🇲🇽 México</option>
              <option value="peru">🇵🇪 Perú</option>
            </select>
          </div>

          {/* Search Form */}
          <div className="bg-slate-800/50 border border-slate-700 rounded-2xl p-6">
            <div className="text-xs font-bold text-slate-400 mb-4 uppercase tracking-wide">
              Buscar ruta
            </div>

            {/* Origin */}
            <div className="mb-4 relative">
              <label className="block text-xs font-semibold text-slate-400 mb-2">
                {serviceType === 'delivery' ? 'Dirección de recogida' : 'Origen'}
              </label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-green-500" />
                <input
                  type="text"
                  value={origin}
                  onChange={handleOriginChange}
                  onFocus={() => origin.length >= 3 && setShowOriginSuggestions(originSuggestions.length > 0)}
                  onBlur={() => setTimeout(() => setShowOriginSuggestions(false), 200)}
                  placeholder="Escribe una dirección, lugar o punto de referencia"
                  className="w-full bg-slate-700 text-white placeholder-slate-400 pl-11 pr-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {showOriginSuggestions && (
                <div className="absolute z-10 w-full mt-2 bg-slate-700 border border-slate-600 rounded-xl shadow-xl max-h-60 overflow-auto">
                  {originSuggestions.map((suggestion, idx) => (
                    <div
                      key={idx}
                      onMouseDown={() => selectOriginSuggestion(suggestion)}
                      className="px-4 py-3 hover:bg-slate-600 cursor-pointer text-sm text-slate-200 border-b border-slate-600 last:border-b-0 flex items-center gap-2"
                    >
                      <MapPin className="w-4 h-4 text-slate-400 flex-shrink-0" />
                      <span className="flex-1">{suggestion}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Destination */}
            <div className="mb-4 relative">
              <label className="block text-xs font-semibold text-slate-400 mb-2">
                {serviceType === 'delivery' ? 'Dirección de entrega' : 'Destino'}
              </label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-red-500" />
                <input
                  type="text"
                  value={destination}
                  onChange={handleDestChange}
                  onFocus={() => destination.length >= 3 && setShowDestSuggestions(destSuggestions.length > 0)}
                  onBlur={() => setTimeout(() => setShowDestSuggestions(false), 200)}
                  placeholder="Escribe una dirección, lugar o punto de referencia"
                  className="w-full bg-slate-700 text-white placeholder-slate-400 pl-11 pr-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {showDestSuggestions && (
                <div className="absolute z-10 w-full mt-2 bg-slate-700 border border-slate-600 rounded-xl shadow-xl max-h-60 overflow-auto">
                  {destSuggestions.map((suggestion, idx) => (
                    <div
                      key={idx}
                      onMouseDown={() => selectDestSuggestion(suggestion)}
                      className="px-4 py-3 hover:bg-slate-600 cursor-pointer text-sm text-slate-200 border-b border-slate-600 last:border-b-0 flex items-center gap-2"
                    >
                      <MapPin className="w-4 h-4 text-slate-400 flex-shrink-0" />
                      <span className="flex-1">{suggestion}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Geolocation */}
            {!geo && (
              <button
                onClick={getGeolocation}
                disabled={geoLoading}
                className="w-full bg-slate-700 hover:bg-slate-600 disabled:bg-slate-600 disabled:cursor-not-allowed text-slate-200 px-4 py-3 rounded-xl flex items-center justify-center gap-2 mb-4 transition-all duration-200 border border-slate-600"
              >
                <MapPin className="w-5 h-5" />
                <span>{geoLoading ? 'Obteniendo ubicación...' : 'Usar mi ubicación como origen'}</span>
              </button>
            )}

            {/* Calculate */}
            <button
              onClick={handleCalculate}
              disabled={!origin.trim() || !destination.trim()}
              className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-slate-600 disabled:cursor-not-allowed text-white px-4 py-3 rounded-xl transition-all duration-200 flex items-center justify-center gap-2 font-bold"
            >
              <Calculator className="w-5 h-5" />
              <span>
                {serviceType === 'transport' ? 'Calcular transporte' :
                 serviceType === 'moto' ? 'Calcular moto' : 'Calcular envío'}
              </span>
            </button>
          </div>

          {/* Distance Info */}
          {calculated && distance && (
            <div
              className="rounded-xl p-4 border-2"
              style={{
                backgroundColor: getTraffic().color,
                borderColor: getTraffic().textColor,
                color: getTraffic().textColor
              }}
            >
              <p className="font-bold text-center">
                📏 Distancia: {distance.toFixed(1)} km • {getTraffic().text}
              </p>
            </div>
          )}

          {/* Filters */}
          {calculated && sortedResults.length > 0 && (
            <div className="bg-slate-800/50 border border-slate-700 rounded-2xl p-6">
              <div className="text-xs font-bold text-slate-400 mb-4 uppercase tracking-wide">
                Ordenar por
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <button
                  onClick={() => setSortBy('default')}
                  className={`px-4 py-2 rounded-xl font-bold text-sm transition-all ${
                    sortBy === 'default'
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                  }`}
                >
                  Default
                </button>
                <button
                  onClick={() => setSortBy('price-asc')}
                  className={`px-4 py-2 rounded-xl font-bold text-sm transition-all ${
                    sortBy === 'price-asc'
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                  }`}
                >
                  💰 Más barato
                </button>
                <button
                  onClick={() => setSortBy('time-asc')}
                  className={`px-4 py-2 rounded-xl font-bold text-sm transition-all ${
                    sortBy === 'time-asc'
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                  }`}
                >
                  ⚡ Más rápido
                </button>
                {currentUser && (
                  <button
                    onClick={() => setSortBy('for-me')}
                    className={`px-4 py-2 rounded-xl font-bold text-sm transition-all ${
                      sortBy === 'for-me'
                        ? 'bg-blue-600 text-white'
                        : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                    }`}
                  >
                    ⭐ Para mí
                  </button>
                )}
              </div>
            </div>
          )}

          {/* Results */}
          {sortedResults.length > 0 && (
            <div>
              <div className="text-xs font-bold text-slate-400 mb-4 uppercase tracking-wide">
                Resultados ({sortedResults.length})
              </div>

              <div className="grid gap-4">
                {sortedResults.map((result, idx) => {
                  const cheapest = getCheapest();
                  const fastest = getFastest();
                  const isCheapest = cheapest && result.price === cheapest.price;
                  const isFastest = fastest && result.eta === fastest.eta;
                  const bookingCount = currentUser?.bookingCount?.[result.serviceName] || 0;

                  return (
                    <div
                      key={idx}
                      className="bg-slate-800/70 rounded-xl p-4 border-l-4 hover:bg-slate-800 transition-all"
                      style={{ borderLeftColor: result.color }}
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div>
                          <h3 className="font-bold text-white text-lg">{result.displayName}</h3>
                          <p className="text-sm text-slate-400">{result.typeName}</p>
                        </div>

                        <div className="text-right">
                          <p className="text-2xl font-black text-white">
                            {servicesConfig[country].currency} {result.price.toLocaleString()}
                          </p>
                          <p className="text-xs text-slate-400 flex items-center gap-1 justify-end mt-1">
                            <Clock className="w-3 h-3" />
                            {result.eta} min
                          </p>
                        </div>
                      </div>

                      {currentUser && (
                        <div className="flex flex-wrap gap-2 mb-3">
                          {isCheapest && (
                            <span className="bg-green-900/30 border border-green-700/50 text-green-400 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1">
                              <TrendingDown className="w-3 h-3" />
                              Más barato ahora
                            </span>
                          )}
                          {isFastest && (
                            <span className="bg-blue-900/30 border border-blue-700/50 text-blue-400 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1">
                              <Zap className="w-3 h-3" />
                              Más rápido ahora
                            </span>
                          )}
                          {bookingCount >= 4 && (
                            <span className="bg-purple-900/30 border border-purple-700/50 text-purple-400 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1">
                              <Star className="w-3 h-3" />
                              Usado {bookingCount}x
                            </span>
                          )}
                        </div>
                      )}

                      <button
                        onClick={() => handleBooking(result.serviceName)}
                        className="w-full text-white px-4 py-3 rounded-xl font-bold hover:opacity-90 transition-all"
                        style={{ backgroundColor: result.color }}
                      >
                        Reservar
                      </button>
                    </div>
                  );
                })}
              </div>

              {!currentUser && (
                <div className="mt-4 bg-blue-900/30 border border-blue-700/50 rounded-xl p-4">
                  <p className="text-blue-200 text-sm mb-3 text-center">
                    🔒 <strong>Inicia sesión</strong> para ver insights personalizados, guardar favoritos y acceder a tu historial
                  </p>
                  <button
                    onClick={() => setShowLogin(true)}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-bold"
                  >
                    Iniciar sesión
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Bottom Nav */}
      <div className="fixed bottom-0 left-0 right-0 bg-slate-800 border-t border-slate-700 px-4 py-3 shadow-lg z-50">
        <div className="max-w-6xl mx-auto flex items-center justify-around gap-2">
          <button
            onClick={() => setShowChat(true)}
            className="flex flex-col items-center gap-1 text-slate-300 hover:text-white transition-colors"
          >
            <MessageSquare className="w-6 h-6" />
            <span className="text-xs font-semibold">Asistente</span>
          </button>

          {currentUser ? (
            <button
              onClick={() => setShowProfile(true)}
              className="flex flex-col items-center gap-1 text-blue-400 hover:text-blue-300 transition-colors"
            >
              <User className="w-6 h-6" />
              <span className="text-xs font-semibold">Perfil</span>
            </button>
          ) : (
            <button
              onClick={() => setShowLogin(true)}
              className="flex flex-col items-center gap-1 text-white bg-blue-600 px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors relative"
            >
              <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
              <User className="w-6 h-6" />
              <span className="text-xs font-semibold">Iniciar sesión</span>
            </button>
          )}
        </div>
      </div>

      {/* Login Modal */}
      {showLogin && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowLogin(false)}
          />

          <div className="relative bg-slate-800 rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-white">Iniciar sesión</h3>
              <button
                onClick={() => setShowLogin(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Nombre</label>
                <input
                  type="text"
                  value={userName}
                  onChange={(e) => setUserName(e.target.value)}
                  placeholder="Tu nombre"
                  className="w-full bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2">Email</label>
                <input
                  type="email"
                  value={userEmail}
                  onChange={(e) => setUserEmail(e.target.value)}
                  placeholder="tu@email.com"
                  onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
                  className="w-full bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <button
                onClick={handleLogin}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-xl font-bold"
              >
                Continuar
              </button>

              <p className="text-xs text-slate-400 text-center">
                Al continuar, aceptas nuestros términos y condiciones
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Profile Modal */}
      {showProfile && currentUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowProfile(false)}
          />

          <div className="relative bg-slate-800 rounded-2xl p-6 w-full max-w-2xl shadow-2xl max-h-[90vh] overflow-y-auto my-8">
            <div className="flex items-center justify-between mb-6 sticky top-0 bg-slate-800 pb-4 border-b border-slate-700">
              <h3 className="text-xl font-bold text-white">Mi Perfil</h3>
              <button
                onClick={() => setShowProfile(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-6">
              <div className="bg-slate-700/50 p-4 rounded-xl">
                <p className="text-sm text-slate-400">Email</p>
                <p className="text-white font-semibold">{currentUser.email}</p>
              </div>

              <div className="bg-slate-700/50 p-4 rounded-xl">
                <p className="text-sm text-slate-400">Nombre</p>
                <p className="text-white font-semibold">{currentUser.name}</p>
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2 flex items-center gap-2">
                  <Home className="w-4 h-4" />
                  Dirección de casa
                </label>
                <input
                  type="text"
                  value={homeAddress}
                  onChange={(e) => setHomeAddress(e.target.value)}
                  placeholder="Tu dirección de casa"
                  className="w-full bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-300 mb-2 flex items-center gap-2">
                  <Briefcase className="w-4 h-4" />
                  Dirección de oficina
                </label>
                <input
                  type="text"
                  value={officeAddress}
                  onChange={(e) => setOfficeAddress(e.target.value)}
                  placeholder="Tu dirección de oficina"
                  className="w-full bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <button
                onClick={updateProfile}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-xl font-bold"
              >
                Guardar cambios
              </button>

              {(homeAddress || officeAddress) && (
                <div>
                  <h4 className="text-sm font-bold text-slate-300 mb-3">Accesos rápidos</h4>
                  <div className="space-y-2">
                    {homeAddress && (
                      <button
                        onClick={() => {
                          setOrigin(homeAddress);
                          setShowProfile(false);
                        }}
                        className="w-full bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 rounded-xl flex items-center gap-2 font-semibold"
                      >
                        <Home className="w-4 h-4" />
                        Desde Casa
                      </button>
                    )}
                    {officeAddress && (
                      <button
                        onClick={() => {
                          setOrigin(officeAddress);
                          setShowProfile(false);
                        }}
                        className="w-full bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 rounded-xl flex items-center gap-2 font-semibold"
                      >
                        <Briefcase className="w-4 h-4" />
                        Desde Oficina
                      </button>
                    )}
                  </div>
                </div>
              )}

              {history.length > 0 && (
                <div>
                  <h4 className="text-sm font-bold text-slate-300 mb-3 flex items-center gap-2">
                    <History className="w-4 h-4" />
                    Historial ({history.length})
                  </h4>
                  <div className="space-y-2 max-h-60 overflow-y-auto">
                    {history.map((route) => (
                      <div
                        key={route.id}
                        className="bg-slate-700/50 p-3 rounded-xl flex items-center justify-between gap-3"
                      >
                        <div className="flex-1 min-w-0">
                          <p className="text-sm text-white font-semibold truncate">
                            {route.from} → {route.to}
                          </p>
                          <p className="text-xs text-slate-400">
                            {new Date(route.timestamp).toLocaleDateString()}
                          </p>
                        </div>
                        <div className="flex gap-2 flex-shrink-0">
                          <button
                            onClick={() => toggleFavorite(route)}
                            className="text-yellow-400 hover:text-yellow-300"
                          >
                            <Star
                              className={`w-5 h-5 ${favorites.some(f => f.id === route.id) ? 'fill-current' : ''}`}
                            />
                          </button>
                          <button
                            onClick={() => loadRoute(route)}
                            className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-lg text-xs font-bold"
                          >
                            Repetir
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {favorites.length > 0 && (
                <div>
                  <h4 className="text-sm font-bold text-slate-300 mb-3 flex items-center gap-2">
                    <Star className="w-4 h-4 fill-current text-yellow-400" />
                    Favoritos ({favorites.length})
                  </h4>
                  <div className="space-y-2">
                    {favorites.map((route) => (
                      <div
                        key={route.id}
                        className="bg-yellow-900/20 border border-yellow-700/50 p-3 rounded-xl flex items-center justify-between gap-3"
                      >
                        <div className="flex-1 min-w-0">
                          <p className="text-sm text-white font-semibold truncate">
                            {route.from} → {route.to}
                          </p>
                        </div>
                        <button
                          onClick={() => loadRoute(route)}
                          className="bg-yellow-600 hover:bg-yellow-700 text-white px-3 py-1 rounded-lg text-xs font-bold flex-shrink-0"
                        >
                          Usar
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <button
                onClick={handleLogout}
                className="w-full bg-red-600 hover:bg-red-700 text-white px-4 py-3 rounded-xl font-bold flex items-center justify-center gap-2"
              >
                <LogOut className="w-5 h-5" />
                Cerrar sesión
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Chat Modal */}
      {showChat && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowChat(false)}
          />

          <div className="relative bg-slate-800 rounded-2xl w-full max-w-2xl h-[80vh] flex flex-col shadow-2xl">
            <div className="bg-slate-700/50 px-4 py-4 border-b border-slate-600 flex items-center justify-between rounded-t-2xl">
              <h3 className="font-bold text-white flex items-center gap-2">
                <MessageSquare className="w-5 h-5" />
                Asistente de Rutas
              </h3>
              <button
                onClick={() => setShowChat(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 bg-slate-900/50">
              {messages.map((msg, i) => (
                <div
                  key={i}
                  className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[85%] rounded-2xl px-4 py-3 ${
                      msg.role === 'user'
                        ? 'bg-blue-600 text-white'
                        : msg.role === 'system'
                        ? 'bg-green-900/30 border border-green-700/50 text-green-200'
                        : 'bg-slate-700 text-slate-100'
                    }`}
                  >
                    <p className="text-sm">{msg.content}</p>
                  </div>
                </div>
              ))}
              {loading && (
                <div className="flex justify-start">
                  <div className="bg-slate-700 text-slate-100 rounded-2xl px-4 py-3">
                    <p className="text-sm">Escribiendo...</p>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            <div className="bg-slate-800 border-t border-slate-700 px-4 py-4 rounded-b-2xl">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="Escribe tu consulta..."
                  className="flex-1 bg-slate-700 text-white px-4 py-3 rounded-xl border border-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button
                  onClick={handleSend}
                  disabled={loading || !input.trim()}
                  className="bg-blue-600 hover:bg-blue-700 disabled:bg-slate-600 disabled:cursor-not-allowed text-white px-4 py-3 rounded-xl"
                >
                  <Send className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
