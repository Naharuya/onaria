// Server-side permission matrix for the app administrator. Unknown roles or permissions are denied.
export const ROLES = Object.freeze(['owner', 'admin', 'editor', 'reviewer', 'support', 'operator', 'viewer']);

const matrix = {
  owner: ['*'],
  admin: ['overview:read', 'feedback:read', 'settings:read', 'settings:write', 'content:write', 'content:review', 'content:approve', 'content:publish', 'content:archive', 'content:read',
    'support:read', 'support:write', 'support:approve', 'support:delete', 'audit:read'],
  editor: ['overview:read', 'feedback:read', 'content:read', 'content:write'],
  reviewer: ['overview:read', 'content:read', 'content:review'],
  support: ['feedback:read', 'support:read', 'support:write'],
  operator: ['overview:read', 'audit:read'],
  viewer: ['overview:read', 'feedback:read'],
};

export function can(role, permission) {
  const granted = Object.hasOwn(matrix, role) ? matrix[role] : [];
  return granted.includes('*') || granted.includes(permission);
}

export function isRole(value) {
  return typeof value === 'string' && ROLES.includes(value);
}

// Express middleware: the session role is resolved by adminAuth on every request.
export function requirePermission(permission, { onDenied } = {}) {
  return (req, res, next) => {
    const admin = res.locals.admin;
    if (!admin || !can(admin.role, permission)) {
      try { onDenied?.(req, res, permission); } catch { /* Denial must not depend on logging. */ }
      return res.status(403).json({ code: 'FORBIDDEN', message: '이 작업을 할 권한이 없습니다.' });
    }
    return next();
  };
}
