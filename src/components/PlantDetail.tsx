import { useState, useEffect } from 'react';
import { getPlantInstanceByPinId } from '../lib/plantInstances';
import { listCareEventsByPlantInstance } from '../lib/careEvents';
import type { PlantInstance, PlantDetails, CareEvent } from '../types/types';

type Props = {
  pinId: string;
  onClose: () => void;
  onEdit?: () => void;
};

type TabType = 'details' | 'care' | 'photos';

export default function PlantDetail({ pinId, onClose, onEdit }: Props) {
  const [plantInstance, setPlantInstance] = useState<PlantInstance | null>(null);
  const [plantDetails, setPlantDetails] = useState<PlantDetails | null>(null);
  const [careEvents, setCareEvents] = useState<CareEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabType>('details');

  useEffect(() => {
    console.log('PlantDetail: Loading data for pinId:', pinId);
    loadPlantData();
  }, [pinId]);

  const loadPlantData = async () => {
    console.log('PlantDetail: Starting to load plant data for pinId:', pinId);
    setLoading(true);
    try {
      const instance = await getPlantInstanceByPinId(pinId);
      console.log('PlantDetail: Got plant instance:', instance);
      if (instance) {
        setPlantInstance(instance);
        setPlantDetails(instance.plant_details || null);
        
        // Load care events
        const events = await listCareEventsByPlantInstance(instance.id);
        console.log('PlantDetail: Loaded care events:', events);
        setCareEvents(events);
      } else {
        console.log('PlantDetail: No plant instance found for pinId:', pinId);
        setPlantInstance(null);
        setPlantDetails(null);
        setCareEvents([]);
      }
    } catch (error) {
      console.error('Error loading plant data:', error);
      setPlantInstance(null);
      setPlantDetails(null);
      setCareEvents([]);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
  };

  const getHealthStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#059669';
      case 'fair': return '#d97706';
      case 'poor': return '#dc2626';
      case 'dead': return '#6b7280';
      default: return '#6b7280';
    }
  };

  const getHealthStatusText = (status: string) => {
    return status.charAt(0).toUpperCase() + status.slice(1);
  };

  if (loading) {
    return (
      <div className="modal-backdrop" onClick={onClose}>
        <div className="modal modal--large" onClick={(e) => e.stopPropagation()}>
          <div style={{ padding: '32px', textAlign: 'center' }}>
            <div style={{ fontSize: '16px', color: '#6b7280' }}>Loading plant details...</div>
          </div>
        </div>
      </div>
    );
  }

  if (!plantInstance) {
    return (
      <div className="modal-backdrop" onClick={onClose}>
        <div className="modal modal--large" onClick={(e) => e.stopPropagation()}>
          <div style={{ padding: '32px', textAlign: 'center' }}>
            <div style={{ fontSize: '16px', color: '#6b7280' }}>Plant not found</div>
            <button className="ui-btn ui-btn--sm" onClick={onClose} style={{ marginTop: '16px' }}>
              Close
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal modal--large" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="modal-header">
          <div className="modal-title">
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{
                width: '40px',
                height: '40px',
                borderRadius: '50%',
                background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white',
                fontSize: '20px'
              }}>
                🌿
              </div>
              <div>
                <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '600' }}>
                  {plantInstance.plant_details?.name || 'Unknown Plant'}
                </h2>
                {plantInstance.plant_details?.scientific_name && (
                  <div style={{ fontSize: '14px', color: '#6b7280', fontStyle: 'italic' }}>
                    {plantInstance.plant_details.scientific_name}
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="modal-actions">
            {onEdit && (
              <button className="ui-btn ui-btn--sm" onClick={onEdit}>
                Edit
              </button>
            )}
            <button className="ui-btn ui-btn--sm ui-btn--ghost" onClick={onClose}>
              Close
            </button>
          </div>
        </div>

        {/* Quick Info Cards */}
        {plantDetails && (
          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', 
            gap: '12px', 
            marginBottom: '24px' 
          }}>
            <div className="card" style={{ padding: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '12px', color: '#6b7280', marginBottom: '4px' }}>Sun</div>
              <div style={{ fontSize: '14px', fontWeight: '500' }}>
                {plantDetails.sun_exposure?.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) || 'Unknown'}
              </div>
            </div>
            <div className="card" style={{ padding: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '12px', color: '#6b7280', marginBottom: '4px' }}>Water</div>
              <div style={{ fontSize: '14px', fontWeight: '500' }}>
                {plantDetails.water_needs?.charAt(0).toUpperCase() + plantDetails.water_needs?.slice(1) || 'Unknown'}
              </div>
            </div>
            <div className="card" style={{ padding: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '12px', color: '#6b7280', marginBottom: '4px' }}>Health</div>
              <div style={{ 
                fontSize: '14px', 
                fontWeight: '500',
                color: getHealthStatusColor(plantInstance.health_status)
              }}>
                {getHealthStatusText(plantInstance.health_status)}
              </div>
            </div>
            {plantDetails.mature_height && (
              <div className="card" style={{ padding: '12px', textAlign: 'center' }}>
                <div style={{ fontSize: '12px', color: '#6b7280', marginBottom: '4px' }}>Height</div>
                <div style={{ fontSize: '14px', fontWeight: '500' }}>
                  {plantDetails.mature_height}" max
                </div>
              </div>
            )}
          </div>
        )}

        {/* Tab Navigation */}
        <div style={{ 
          display: 'flex', 
          borderBottom: '1px solid #e5e7eb',
          marginBottom: '24px'
        }}>
          {(['details', 'care', 'photos'] as TabType[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              style={{
                padding: '12px 16px',
                border: 'none',
                background: 'none',
                cursor: 'pointer',
                borderBottom: activeTab === tab ? '2px solid #10b981' : '2px solid transparent',
                color: activeTab === tab ? '#10b981' : '#6b7280',
                fontWeight: activeTab === tab ? '600' : '400',
                fontSize: '14px'
              }}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div style={{ minHeight: '300px' }}>
          {activeTab === 'details' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Plant Information */}
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '12px' }}>
                  Plant Information
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {plantDetails?.family && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Family:</span>
                      <span>{plantDetails.family}</span>
                    </div>
                  )}
                  {plantDetails?.growth_habit && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Growth Habit:</span>
                      <span>{plantDetails.growth_habit.charAt(0).toUpperCase() + plantDetails.growth_habit.slice(1)}</span>
                    </div>
                  )}
                  {plantDetails?.soil_type && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Soil Type:</span>
                      <span>{plantDetails.soil_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
                    </div>
                  )}
                  {plantDetails?.fertilizer_needs && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Fertilizer:</span>
                      <span>{plantDetails.fertilizer_needs.charAt(0).toUpperCase() + plantDetails.fertilizer_needs.slice(1)}</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Instance Information */}
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '12px' }}>
                  This Plant
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {plantInstance.planted_date && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Planted:</span>
                      <span>{formatDate(plantInstance.planted_date)}</span>
                    </div>
                  )}
                  {plantInstance.source && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Source:</span>
                      <span>{plantInstance.source.charAt(0).toUpperCase() + plantInstance.source.slice(1)}</span>
                    </div>
                  )}
                  {plantInstance.cost && (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#6b7280' }}>Cost:</span>
                      <span>${plantInstance.cost.toFixed(2)}</span>
                    </div>
                  )}
                  {plantInstance.notes && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                      <span style={{ color: '#6b7280' }}>Notes:</span>
                      <span style={{ fontSize: '14px' }}>{plantInstance.notes}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}

          {activeTab === 'care' && (
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <h3 style={{ fontSize: '16px', fontWeight: '600', margin: 0 }}>
                  Care History
                </h3>
                <button className="ui-btn ui-btn--sm">
                  Add Care Event
                </button>
              </div>
              
              {careEvents.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '32px', color: '#6b7280' }}>
                  No care events recorded yet.
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {careEvents.map((event) => (
                    <div key={event.id} className="card" style={{ padding: '16px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '12px',
                            fontWeight: '500',
                            background: '#f3f4f6',
                            color: '#374151'
                          }}>
                            {event.event_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                          </span>
                          <span style={{ fontSize: '14px', color: '#6b7280' }}>
                            {formatDate(event.event_date)}
                          </span>
                        </div>
                        {event.cost && (
                          <span style={{ fontSize: '14px', fontWeight: '500' }}>
                            ${event.cost.toFixed(2)}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: '14px', marginBottom: '4px' }}>
                        {event.description}
                      </div>
                      {event.notes && (
                        <div style={{ fontSize: '13px', color: '#6b7280' }}>
                          {event.notes}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'photos' && (
            <div style={{ textAlign: 'center', padding: '32px', color: '#6b7280' }}>
              <div style={{ fontSize: '16px', marginBottom: '8px' }}>📸</div>
              <div>Photo gallery coming soon</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
