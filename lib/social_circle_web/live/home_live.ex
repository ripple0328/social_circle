defmodule SocialCircleWeb.HomeLive do
  use SocialCircleWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]

    # Redirect authenticated users to dashboard
    if current_user_id do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <!-- Navigation -->
      <nav class="bg-white/80 backdrop-blur-md border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-4">
            <!-- Logo -->
            <div class="flex items-center space-x-3">
              <img src="/images/logo.svg" alt="Social Circle" class="w-12 h-12" />
              <span class="text-2xl font-bold text-gray-900">Social Circle</span>
            </div>
            
    <!-- CTA Button -->
            <div>
              <.link
                navigate={~p"/auth"}
                class="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-md hover:shadow-lg"
              >
                Get Started
              </.link>
            </div>
          </div>
        </div>
      </nav>
      
    <!-- Hero Section -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div class="text-center">
          <!-- Main Headline -->
          <h1 class="text-5xl sm:text-6xl font-bold text-gray-900 mb-6 leading-tight">
            Unify Your
            <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Social Media
            </span>
            Experience
          </h1>
          
    <!-- Subtitle -->
          <p class="text-xl text-gray-600 mb-12 max-w-3xl mx-auto leading-relaxed">
            Connect all your social accounts in one place. Manage, monitor, and maximize your social media presence with our powerful unified dashboard.
          </p>
          
    <!-- Primary CTA -->
          <div class="mb-16">
            <.link
              navigate={~p"/auth"}
              class="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-1"
            >
              Get Started
            </.link>
          </div>
          
    <!-- Feature Cards -->
          <div class="grid md:grid-cols-3 gap-8 mb-20">
            <!-- Unified Dashboard -->
            <div class="bg-white/70 backdrop-blur-sm rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-2">
              <div class="w-16 h-16 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-6">
                <.icon name="hero-squares-2x2" class="w-8 h-8 text-white" />
              </div>
              <h3 class="text-xl font-semibold text-gray-900 mb-4">Unified Dashboard</h3>
              <p class="text-gray-600 leading-relaxed">
                View all your social media accounts, posts, and analytics from one centralized dashboard. No more switching between apps.
              </p>
            </div>
            
    <!-- Real-time Sync -->
            <div class="bg-white/70 backdrop-blur-sm rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-2">
              <div class="w-16 h-16 bg-gradient-to-r from-purple-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-6">
                <.icon name="hero-arrow-path" class="w-8 h-8 text-white" />
              </div>
              <h3 class="text-xl font-semibold text-gray-900 mb-4">Real-time Sync</h3>
              <p class="text-gray-600 leading-relaxed">
                Your content and interactions are synced in real-time across all platforms. Stay up-to-date with instant notifications.
              </p>
            </div>
            
    <!-- Privacy First -->
            <div class="bg-white/70 backdrop-blur-sm rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-2">
              <div class="w-16 h-16 bg-gradient-to-r from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
                <.icon name="hero-shield-check" class="w-8 h-8 text-white" />
              </div>
              <h3 class="text-xl font-semibold text-gray-900 mb-4">Privacy First</h3>
              <p class="text-gray-600 leading-relaxed">
                Your data stays secure with enterprise-grade encryption. We never store your passwords or access your private messages.
              </p>
            </div>
          </div>
          
    <!-- User Journey Examples -->
          <div class="bg-white/60 backdrop-blur-sm rounded-3xl p-12 mb-20">
            <h2 class="text-3xl font-bold text-gray-900 mb-8">See How It Works</h2>

            <div class="grid lg:grid-cols-2 gap-12 items-center">
              <!-- Journey Steps -->
              <div class="space-y-8">
                <!-- Step 1 -->
                <div class="flex items-start space-x-4">
                  <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-full flex items-center justify-center font-semibold">
                    1
                  </div>
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-2">Connect Your Accounts</h3>
                    <p class="text-gray-600">
                      Securely link your X (Twitter), Facebook, Google, and Apple accounts with just one click. OAuth ensures your credentials stay safe.
                    </p>
                  </div>
                </div>
                
    <!-- Step 2 -->
                <div class="flex items-start space-x-4">
                  <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-full flex items-center justify-center font-semibold">
                    2
                  </div>
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-2">Unified Dashboard</h3>
                    <p class="text-gray-600">
                      Access your personalized dashboard where all your social media activity is consolidated in real-time.
                    </p>
                  </div>
                </div>
                
    <!-- Step 3 -->
                <div class="flex items-start space-x-4">
                  <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-r from-pink-500 to-red-500 text-white rounded-full flex items-center justify-center font-semibold">
                    3
                  </div>
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-2">Manage & Monitor</h3>
                    <p class="text-gray-600">
                      Track engagement, manage multiple accounts, and get insights across all your social platforms from one place.
                    </p>
                  </div>
                </div>
              </div>
              
    <!-- Visual Representation -->
              <div class="relative">
                <div class="bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl p-8 min-h-96 flex items-center justify-center">
                  <div class="grid grid-cols-2 gap-6">
                    <!-- Social Platform Icons -->
                    <div class="bg-black text-white p-4 rounded-xl shadow-lg transform rotate-3 hover:rotate-0 transition-transform">
                      <.icon name="hero-at-symbol" class="w-8 h-8" />
                      <p class="text-xs mt-2 font-semibold">X (Twitter)</p>
                    </div>
                    <div class="bg-blue-600 text-white p-4 rounded-xl shadow-lg transform -rotate-3 hover:rotate-0 transition-transform">
                      <.icon name="hero-user-group" class="w-8 h-8" />
                      <p class="text-xs mt-2 font-semibold">Facebook</p>
                    </div>
                    <div class="bg-red-500 text-white p-4 rounded-xl shadow-lg transform rotate-2 hover:rotate-0 transition-transform">
                      <.icon name="hero-globe-alt" class="w-8 h-8" />
                      <p class="text-xs mt-2 font-semibold">Google</p>
                    </div>
                    <div class="bg-gray-800 text-white p-4 rounded-xl shadow-lg transform -rotate-2 hover:rotate-0 transition-transform">
                      <.icon name="hero-device-phone-mobile" class="w-8 h-8" />
                      <p class="text-xs mt-2 font-semibold">Apple</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Trust Indicators -->
          <div class="grid md:grid-cols-4 gap-8 text-center">
            <div class="flex flex-col items-center">
              <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mb-4">
                <.icon name="hero-shield-check" class="w-6 h-6 text-green-600" />
              </div>
              <h3 class="font-semibold text-gray-900">Secure</h3>
              <p class="text-sm text-gray-600 mt-1">Enterprise-grade encryption</p>
            </div>

            <div class="flex flex-col items-center">
              <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-4">
                <.icon name="hero-eye-slash" class="w-6 h-6 text-blue-600" />
              </div>
              <h3 class="font-semibold text-gray-900">Private</h3>
              <p class="text-sm text-gray-600 mt-1">Your data stays yours</p>
            </div>

            <div class="flex flex-col items-center">
              <div class="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mb-4">
                <.icon name="hero-bolt" class="w-6 h-6 text-purple-600" />
              </div>
              <h3 class="font-semibold text-gray-900">Fast</h3>
              <p class="text-sm text-gray-600 mt-1">Real-time synchronization</p>
            </div>

            <div class="flex flex-col items-center">
              <div class="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center mb-4">
                <.icon name="hero-key" class="w-6 h-6 text-indigo-600" />
              </div>
              <h3 class="font-semibold text-gray-900">No Passwords</h3>
              <p class="text-sm text-gray-600 mt-1">OAuth-based authentication</p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Footer -->
      <footer class="bg-white/50 backdrop-blur-sm border-t border-gray-200 py-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex flex-col md:flex-row justify-between items-center">
            <div class="flex items-center space-x-3 mb-4 md:mb-0">
              <img src="/images/logo.svg" alt="Social Circle" class="w-8 h-8" />
              <span class="text-lg font-semibold text-gray-900">Social Circle</span>
            </div>
            <div class="flex space-x-6 text-sm text-gray-600">
              <a href="/terms" class="hover:text-gray-900 transition-colors">Terms of Service</a>
              <a href="/privacy" class="hover:text-gray-900 transition-colors">Privacy Policy</a>
              <a href="/support" class="hover:text-gray-900 transition-colors">Support</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
    """
  end
end
